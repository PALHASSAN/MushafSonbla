//
//  LockScreenMetadataManager.swift
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
public final class LockScreenMetadataManager {
    public static let shared = LockScreenMetadataManager()
    
    private init() {}
    
    public struct RemoteCommandConfig: Sendable {
        public var onPlayPause: (@MainActor () -> Void)?
        public var onNextTrack: (@MainActor () -> Void)?
        public var onPreviousTrack: (@MainActor () -> Void)?
        public var onSkipForward: (@MainActor () -> Void)?
        public var onSkipBackward: (@MainActor () -> Void)?
        public var onChangePlaybackPosition: (@MainActor (TimeInterval) -> Void)?
        
        public init(
            onPlayPause: (@MainActor () -> Void)? = nil,
            onNextTrack: (@MainActor () -> Void)? = nil,
            onPreviousTrack: (@MainActor () -> Void)? = nil,
            onSkipForward: (@MainActor () -> Void)? = nil,
            onSkipBackward: (@MainActor () -> Void)? = nil,
            onChangePlaybackPosition: (@MainActor (TimeInterval) -> Void)? = nil
        ) {
            self.onPlayPause = onPlayPause
            self.onNextTrack = onNextTrack
            self.onPreviousTrack = onPreviousTrack
            self.onSkipForward = onSkipForward
            self.onSkipBackward = onSkipBackward
            self.onChangePlaybackPosition = onChangePlaybackPosition
        }
    }
    
    public func setNowPlayingInfo(
        surahName: String,
        reciterName: String,
        duration: TimeInterval,
        elapsedTime: TimeInterval,
        rate: Float,
        artworkImageName: String? = nil
    ) {
        var info: [String: Any] = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        
        info[MPMediaItemPropertyTitle] = surahName
        info[MPMediaItemPropertyArtist] = reciterName
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = rate
        
        #if canImport(UIKit)
        if let name = artworkImageName, let image = UIImage(named: name, in: Bundle.module, with: nil) ?? UIImage(named: name) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
            info[MPMediaItemPropertyArtwork] = artwork
        }
        #endif
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    public func updateElapsedTime(_ currentTime: TimeInterval, rate: Float) {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = rate
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    public func setupRemoteCommands(_ config: RemoteCommandConfig) {
        let commandCenter = MPRemoteCommandCenter.shared()

        func register(_ command: MPRemoteCommand, handler: (@MainActor () -> Void)?) {
            command.removeTarget(nil)
            if let h = handler {
                command.addTarget { _ in
                    h()
                    return .success
                }
                command.isEnabled = true
            } else {
                command.isEnabled = false
            }
        }

        register(commandCenter.playCommand, handler: config.onPlayPause)
        register(commandCenter.pauseCommand, handler: config.onPlayPause)
        register(commandCenter.nextTrackCommand, handler: config.onNextTrack)
        register(commandCenter.previousTrackCommand, handler: config.onPreviousTrack)
        register(commandCenter.skipForwardCommand, handler: config.onSkipForward)
        register(commandCenter.skipBackwardCommand, handler: config.onSkipBackward)
        
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        if let onChange = config.onChangePlaybackPosition {
            commandCenter.changePlaybackPositionCommand.addTarget { event in
                guard let posEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
                onChange(posEvent.positionTime)
                return .success
            }
            commandCenter.changePlaybackPositionCommand.isEnabled = true
        } else {
            commandCenter.changePlaybackPositionCommand.isEnabled = false
        }
    }

    public func clearRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        func clear(_ command: MPRemoteCommand) {
            command.removeTarget(nil)
            command.isEnabled = false
        }
        clear(commandCenter.playCommand)
        clear(commandCenter.pauseCommand)
        clear(commandCenter.nextTrackCommand)
        clear(commandCenter.previousTrackCommand)
        clear(commandCenter.skipForwardCommand)
        clear(commandCenter.skipBackwardCommand)
        clear(commandCenter.changePlaybackPositionCommand)
    }
}
