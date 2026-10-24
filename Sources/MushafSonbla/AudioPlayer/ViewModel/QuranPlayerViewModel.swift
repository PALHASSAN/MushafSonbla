//
//  QuranPlayerViewModel.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import AVFoundation
import Combine
import Foundation
import Observation

public enum TimingProviderError: Error {
    case invalidURL
    case missingData
    case unsupportedTimingSource
}

@MainActor
@Observable
public final class QuranPlayerViewModel {
    public enum PlaybackState: Equatable, Sendable {
        case idle
        case loading
        case ready
        case playing
        case paused
        case finished
        case failed(String)
    }
    
    public func updateState(for newState: PlaybackState) {
        self.playbackState = newState
    }
    
    public private(set) var playbackState: PlaybackState = .idle
    public private(set) var currentTime: Double = 0
    public private(set) var duration: Double = 0
    public var playbackRate: Float = 1.0 {
        didSet {
            player?.rate = playbackRate
            if playbackState == .playing {
                player?.playImmediately(atRate: playbackRate)
            }
        }
    }
    public private(set) var isBuffering: Bool = false
    public private(set) var isScrubbing: Bool = false
    public var isRepeatEnabled: Bool = false
    public private(set) var currentVerseNumber: Int? = nil
    
    public var sleepMinutesRemaining: Int = 0
    private var sleepTask: Task<Void, Never>?
    
    public var chapterName: String { chapterNameInternal }
    public var reciterName: String { reciterNameInternal }
    public let playbackRates: [Float] = [0.75, 1.0, 1.25, 1.5, 1.75]
    
    private var baseURL: URL?
    public private(set) var chapterNumber: Int
    private var chapterNameInternal: String
    private var reciterNameInternal: String
    public private(set) var reciterId: Int = 1
    private var timingSource: TimingSource = .mp3quran
    
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var statusObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    private var endPlaybackObserver: Any?
    private var pendingSeekVerse: Int?
    private var pendingResumeVerse: Int?
    private var prepareTask: Task<Void, Never>?
    
    private var shouldResumeAfterSeek = false
    private var shouldAutoStart = true
    private var backgroundHelper: BackgroundPlaybackHelper?
    
    public init(baseURL: URL? = nil, chapterNumber: Int = 0, chapterName: String = "", reciterName: String? = nil) {
        self.baseURL = baseURL
        self.chapterNumber = chapterNumber
        self.chapterNameInternal = chapterName
        self.reciterNameInternal = reciterName ?? ""
    }
    
    deinit { MainActor.assumeIsolated { cleanup() } }
    
    public var isPlaying: Bool { playbackState == .playing }
    public var isLoading: Bool { playbackState == .loading }
    public var isPaused: Bool { playbackState == .paused }
    
    public var progress: Double {
        guard duration > 0, currentTime.isFinite, duration.isFinite else { return 0 }
        let ratio = currentTime / duration
        return min(max(ratio, 0), 1)
    }
    
    public var remainingTime: Double {
        guard duration.isFinite, currentTime.isFinite else { return 0 }
        return max(duration - currentTime, 0)
    }
    
    public var errorMessage: String? {
        if case let .failed(message) = playbackState { return message }
        return nil
    }
    
    public var hasValidConfiguration: Bool { chapterNumber > 0 && baseURL != nil }
    
    @discardableResult
    public func configureIfNeeded(
        baseURL: URL, chapterNumber: Int, chapterName: String, reciterName: String, reciterId: Int? = nil, timingSource: TimingSource? = nil
    ) -> Bool {
        let audioChanged = (self.baseURL != baseURL) || (self.chapterNumber != chapterNumber)
        
        self.baseURL = baseURL
        self.chapterNumber = chapterNumber
        self.chapterNameInternal = chapterName
        self.reciterNameInternal = reciterName
        
        if let id = reciterId { self.reciterId = id }
        if let ts = timingSource { self.timingSource = ts }
        
        if audioChanged {
            stop()
            prefetchChapterTimingIfNeeded()
        }
        
        return audioChanged
    }
    
    public func startIfNeeded(autoPlay: Bool = true) {
        shouldAutoStart = autoPlay
        guard hasValidConfiguration else {
            playbackState = .failed("Audio playback is not configured.")
            return
        }
        
        QuranPlayerCoordinator.shared.activatePlayer()
        AudioSessionManager.shared.configureAudioSession()
        ensureBackgroundSupport()
        
        switch playbackState {
        case .idle, .failed: preparePlayer(autoPlay: autoPlay)
        case .paused, .ready, .finished: if autoPlay { play() }
        case .loading, .playing: break
        }
    }
    
    public func stop() {
        cleanup()
        cleanupBackgroundHelper()
        playbackState = .idle
        currentTime = 0
        duration = 0
        currentVerseNumber = nil
        sleepMinutesRemaining = 0
        sleepTask?.cancel()
    }
    
    public func updateChapter(number: Int, name: String) {
        guard number != chapterNumber || name != chapterNameInternal else { return }
        chapterNumber = number
        chapterNameInternal = name
        stop()
        prefetchChapterTimingIfNeeded()
    }
    
    public func updateReciter(baseURL: URL, reciterName: String, reciterId: Int? = nil, timingSource: TimingSource? = nil) {
        let reciterIdChanged = reciterId.map { $0 != self.reciterId } ?? false
        let timingSourceChanged = timingSource.map { $0 != self.timingSource } ?? false
        guard baseURL != self.baseURL || reciterName != reciterNameInternal || reciterIdChanged || timingSourceChanged else { return }
        
        let previousState = playbackState
        let resumeVerse = currentVerseNumber
        let previousTime = currentTime
        let shouldAutoPlay = previousState == .playing
        
        self.baseURL = baseURL
        self.reciterNameInternal = reciterName
        if let reciterId { self.reciterId = reciterId }
        if let timingSource { self.timingSource = timingSource }
        
        prefetchChapterTimingIfNeeded()
        pendingSeekVerse = nil
        
        switch previousState {
        case .playing, .paused, .ready:
            stop()
            if let resumeVerse {
                currentVerseNumber = resumeVerse
                pendingResumeVerse = shouldAutoPlay ? resumeVerse : nil
                pendingSeekVerse = shouldAutoPlay ? nil : resumeVerse
                
                if let timing = AyahTimingService.shared.getTiming(for: self.reciterId, surahId: chapterNumber, ayahId: resumeVerse) {
                    currentTime = Double(timing.start) / 1000.0
                } else {
                    currentTime = previousTime
                }
            } else {
                pendingResumeVerse = nil
                pendingSeekVerse = nil
                currentTime = previousTime
            }
            startIfNeeded(autoPlay: shouldAutoPlay)
        default:
            break
        }
    }
    
    public func updateCurrentVerse() {
        guard chapterNumber > 0, reciterId > 0 else { return }
        let currentTimeMs = Int(currentTime * 1000)
        let newVerseNumber = AyahTimingService.shared.getCurrentVerse(for: reciterId, surahId: chapterNumber, currentTimeMs: currentTimeMs)
        if newVerseNumber != currentVerseNumber {
            currentVerseNumber = newVerseNumber
        }
    }
    
    private func ensureBackgroundSupport() {
        if backgroundHelper == nil {
            let helper = BackgroundPlaybackHelper()
            helper.attach(to: self)
            backgroundHelper = helper
        }
    }
    
    private func cleanupBackgroundHelper() {
        backgroundHelper?.detach()
        backgroundHelper = nil
    }
    
    public func togglePlayback() {
        switch playbackState {
        case .idle, .failed: startIfNeeded(autoPlay: true)
        case .loading: break
        case .ready, .paused, .finished: play()
        case .playing: pause()
        }
    }
    
    public func play() {
        QuranPlayerCoordinator.shared.activatePlayer()
        
        guard let player else {
            preparePlayer(autoPlay: true)
            return
        }
        
        if let pending = pendingResumeVerse,
           let timing = AyahTimingService.shared.getTiming(for: reciterId, surahId: chapterNumber, ayahId: pending) {
            
            let targetSeconds = (pending == 1) ? 0.0 : Double(timing.start) / 1000.0
            pendingResumeVerse = nil
            seek(to: targetSeconds) { [weak self] in
                guard let self, let player = self.player else { return }
                player.playImmediately(atRate: self.playbackRate)
                self.playbackState = .playing
            }
            return
        }
        
        player.playImmediately(atRate: playbackRate)
        playbackState = .playing
    }
    
    public func pause() {
        guard let player, playbackState == .playing else { return }
        player.pause()
        playbackState = .paused
    }
    
    public func startSleepTimer(minutes: Int) {
        sleepMinutesRemaining = minutes
        sleepTask?.cancel()
        
        guard minutes > 0 else { return }
        
        sleepTask = Task { @MainActor [weak self] in
            while let self = self, self.sleepMinutesRemaining > 0 {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { break }
                self.sleepMinutesRemaining -= 1
                if self.sleepMinutesRemaining <= 0 {
                    self.pause()
                    break
                }
            }
        }
    }
    
    @discardableResult
    public func seekToVerse(_ verseNumber: Int) -> Bool {
        guard verseNumber > 0, chapterNumber > 0, reciterId > 0 else { return false }
        guard let timing = AyahTimingService.shared.getTiming(for: reciterId, surahId: chapterNumber, ayahId: verseNumber) else { return false }
        
        let targetSeconds = (verseNumber == 1) ? 0.0 : Double(timing.start) / 1000.0
        
        guard player != nil else {
            pendingSeekVerse = verseNumber
            startIfNeeded(autoPlay: false)
            return true
        }
        
        let shouldResume = isPlaying
        if shouldResume { pause() }
        seek(to: targetSeconds) { [weak self] in
            guard let self else { return }
            self.updateCurrentVerse()
            if shouldResume { self.play() }
        }
        return true
    }
    
    @discardableResult
    public func seekToNextVerse() -> Bool {
        guard chapterNumber > 0, reciterId > 0 else { return false }
        guard let timings = AyahTimingService.shared.getChapterTimings(for: reciterId, surahId: chapterNumber) else { return false }
        
        let sortedAyahs = timings.map { $0.ayah }.sorted()
        guard let lastAyah = sortedAyahs.last else { return false }
        let current = currentVerseNumber ?? sortedAyahs.first ?? 1
        let nextAyah = min(current + 1, lastAyah)
        
        if nextAyah == current && current == lastAyah {
            playNextSurah()
            return true
        }
        
        if nextAyah != current {
            if isPlaying { return seekToVerse(nextAyah) }
            else { setPreviewVerse(nextAyah); return true }
        }
        return false
    }
    
    @discardableResult
    public func seekToPreviousVerse() -> Bool {
        guard chapterNumber > 0, reciterId > 0 else { return false }
        guard let timings = AyahTimingService.shared.getChapterTimings(for: reciterId, surahId: chapterNumber) else { return false }
        
        let sortedAyahs = timings.map { $0.ayah }.sorted()
        guard let firstAyah = sortedAyahs.first else { return false }
        let current = currentVerseNumber ?? firstAyah
        let previousAyah = max(current - 1, firstAyah)
        
        if previousAyah != current {
            if isPlaying { return seekToVerse(previousAyah) }
            else { setPreviewVerse(previousAyah); return true }
        }
        return false
    }
    
    private func playNextSurah() {
        let nextSuraId = self.chapterNumber + 1
        guard nextSuraId <= 114 else { return }
        
        Task {
            let newName: String
            if let sura = try? await QuranDB.shared.getSura(id: nextSuraId) {
                newName = sura.arabicTitle
            } else {
                newName = "سورة \(nextSuraId)"
            }
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.updateChapter(number: nextSuraId, name: newName)
                self.setPreviewVerse(1)
                self.startIfNeeded(autoPlay: true)
            }
        }
    }
    
    public func toggleRepeat() { isRepeatEnabled.toggle() }
    
    public func setPreviewVerse(_ verseNumber: Int) {
        guard verseNumber > 0 else { return }
        currentVerseNumber = verseNumber
        pendingResumeVerse = verseNumber
    }
    
    public func beginScrubbing() {
        guard !isScrubbing, duration > 0 else { return }
        shouldResumeAfterSeek = isPlaying
        pause()
        isScrubbing = true
    }
    
    public func updateScrubbing(progress: Double) {
        guard isScrubbing else { return }
        let clamped = min(max(progress, 0), 1)
        currentTime = clamped * duration
    }
    
    public func endScrubbing(progress: Double) {
        guard isScrubbing else { return }
        let clamped = min(max(progress, 0), 1)
        let targetSeconds = clamped * duration
        isScrubbing = false
        
        seek(to: targetSeconds) { [weak self] in
            guard let self else { return }
            if self.shouldResumeAfterSeek { self.play() }
        }
    }
    
    private func preparePlayer(autoPlay: Bool) {
        cleanup()
        playbackState = .loading
        shouldAutoStart = autoPlay
        prefetchChapterTimingIfNeeded()
        
        prepareTask = Task { [weak self] in
            guard let self else { return }
            do {
                AudioSessionManager.shared.configureAudioSession()
                let audioURL = try await self.resolveAudioURLForPlayback()
                guard !Task.isCancelled else { return }
                self.setupPlayer(with: audioURL)
            } catch {
                if error is CancellationError || Task.isCancelled { return }
                self.playbackState = .failed(error.localizedDescription)
            }
        }
    }
    
    private func prefetchChapterTimingIfNeeded() {
        _ = AyahTimingService.shared.getChapterTimings(for: reciterId, surahId: chapterNumber)
    }
    
    private func resolveAudioURLForPlayback() async throws -> URL {
        guard let baseURL else { throw TimingProviderError.invalidURL }
        let fileName = String(format: "%03d.mp3", chapterNumber)
        return baseURL.appendingPathComponent(fileName)
    }
    
    private func setupPlayer(with audioURL: URL) {
        let asset = AVURLAsset(url: audioURL)
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 0
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        
        let player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = true
        self.player = player
        
        observeStatus(for: playerItem)
        observeTimeControl(for: player)
        observePeriodicTime(for: player)
        observeCompletion(for: playerItem)
    }
    
    private func observeStatus(for item: AVPlayerItem) {
        statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            Task { @MainActor in
                switch item.status {
                case .readyToPlay:
                    self.updateDuration(from: item)
                    
                    if let pending = self.pendingSeekVerse,
                       let timing = AyahTimingService.shared.getTiming(for: self.reciterId, surahId: self.chapterNumber, ayahId: pending) {
                        self.pendingSeekVerse = nil
                        let targetSeconds = (pending == 1) ? 0.0 : Double(timing.start) / 1000.0
                        
                        self.seek(to: targetSeconds) { [weak self] in
                            guard let self else { return }
                            self.currentVerseNumber = pending
                            if self.shouldAutoStart {
                                self.player?.playImmediately(atRate: self.playbackRate)
                                self.playbackState = .playing
                            } else {
                                self.playbackState = .ready
                            }
                        }
                    } else {
                        if self.shouldAutoStart {
                            self.play()
                        } else {
                            self.playbackState = .ready
                        }
                    }
                    
                case .failed:
                    self.playbackState = .failed(item.error?.localizedDescription ?? "Unable to load audio.")
                    self.isBuffering = false
                case .unknown: break
                @unknown default: break
                }
            }
        }
    }
    
    private func observeTimeControl(for player: AVPlayer) {
        timeControlObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor in
                guard let self else { return }
                self.isBuffering = (self.player?.timeControlStatus == .waitingToPlayAtSpecifiedRate)
            }
        }
    }
    
    private func observePeriodicTime(for player: AVPlayer) {
        let interval = CMTime(value: 1, timescale: 10)
        
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let seconds = CMTimeGetSeconds(time)
            
            if !self.isScrubbing, seconds.isFinite {
                self.currentTime = seconds
                self.updateCurrentVerse()
            }
            
            if self.duration == 0, let item = self.player?.currentItem {
                self.updateDuration(from: item)
            }
        }
    }

    private func observeCompletion(for item: AVPlayerItem) {
        endPlaybackObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.isRepeatEnabled {
                    self.seek(to: 0) { [weak self] in self?.play() }
                } else {
                    self.playNextSurah()
                }
            }
        }
    }

    public func seek(to seconds: Double, completion: (@MainActor @Sendable () -> Void)? = nil) {
        guard let player else { return }
        let cmTime = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self, completion] _ in
            Task { @MainActor [weak self] in
                self?.currentTime = seconds
                completion?()
            }
        }
    }

    private func updateDuration(from item: AVPlayerItem) {
        let itemDuration = CMTimeGetSeconds(item.duration)
        if itemDuration.isFinite, itemDuration > 0 { duration = itemDuration }
    }

    private func cleanup() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        statusObservation?.invalidate()
        statusObservation = nil
        timeControlObservation?.invalidate()
        timeControlObservation = nil
        if let endPlaybackObserver {
            NotificationCenter.default.removeObserver(endPlaybackObserver)
            self.endPlaybackObserver = nil
        }
        player?.pause()
        player = nil
        isBuffering = false
        prepareTask?.cancel()
        prepareTask = nil
    }
}
