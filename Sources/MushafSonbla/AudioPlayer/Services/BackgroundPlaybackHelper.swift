//
//  BackgroundPlaybackHelper.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation
import MediaPlayer
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class BackgroundPlaybackHelper {
    private weak var playerViewModel: QuranPlayerViewModel?
    private var timerTask: Task<Void, Never>?
    
    public init() {}
    
    public func attach(to player: QuranPlayerViewModel) {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        guard playerViewModel !== player else { return }
        
        detach()
        playerViewModel = player
        
        AudioSessionManager.shared.configureAudioSession()
        
        #if canImport(UIKit)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        #endif
        
        AudioSessionManager.shared.setupInterruptionHandling(
            onInterruptionBegan: { [weak player] in player?.pause() },
            onInterruptionEnded: { [weak player] in player?.startIfNeeded(autoPlay: true) }
        )
        
        LockScreenMetadataManager.shared.setupRemoteCommands(
            .init(
                onPlayPause: { [weak player] in Task { @MainActor in player?.togglePlayback() } },
                onNextTrack: { [weak player] in Task { @MainActor in _ = player?.seekToNextVerse() } },
                onPreviousTrack: { [weak player] in Task { @MainActor in _ = player?.seekToPreviousVerse() } },
                onChangePlaybackPosition: { [weak player] time in Task { @MainActor in player?.seek(to: time) } }
            )
        )
        
        startObservingPlayer()
        
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if let player = self.playerViewModel, player.isPlaying {
                    LockScreenMetadataManager.shared.updateElapsedTime(player.currentTime, rate: player.playbackRate)
                }
            }
        }
    }
    
    private func startObservingPlayer() {
        guard let player = playerViewModel else { return }
        
        withObservationTracking {
            _ = player.playbackState
            _ = player.currentVerseNumber
            _ = player.isBuffering
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.updateLockScreenNowPlaying()
                self.startObservingPlayer()
            }
        }
    }
    
    private func updateLockScreenNowPlaying() {
        guard let player = playerViewModel else { return }
        
        let state = player.playbackState
        let currentVerse = player.currentVerseNumber
        let isBuffering = player.isBuffering
        
        let duration = TimeInterval(player.duration)
        let elapsed = player.currentTime
        let rate: Float = (state == .playing && !isBuffering) ? player.playbackRate : 0.0
        
        guard duration > 0, !duration.isNaN else { return }
        
        if state == .playing || state == .paused || state == .ready || state == .loading {
            let verseText = currentVerse != nil ? " - آية \(currentVerse!)" : ""
            let title = player.chapterName + verseText
            
            LockScreenMetadataManager.shared.setNowPlayingInfo(
                surahName: title,
                reciterName: player.reciterName,
                duration: duration,
                elapsedTime: elapsed,
                rate: rate
            )
        } else if state == .finished {
            LockScreenMetadataManager.shared.updateElapsedTime(duration, rate: 0.0)
        }
    }

    public func detach() {
        timerTask?.cancel()
        timerTask = nil
        playerViewModel = nil
        LockScreenMetadataManager.shared.clearRemoteCommands()
        #if canImport(UIKit)
        UIApplication.shared.endReceivingRemoteControlEvents()
        #endif
    }
}
