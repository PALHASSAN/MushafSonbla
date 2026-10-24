//
//  AudioSessionManager.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation
import AVFoundation

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
public final class AudioSessionManager: @unchecked Sendable {
    public static let shared = AudioSessionManager()

    private let lock = NSLock()
    private var isConfigured = false
    private var interruptionObserver: Any?

    private init() {}

    public func configureAudioSession() {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }

        lock.lock()
        if isConfigured {
            lock.unlock()
            return
        }
        isConfigured = true
        lock.unlock()

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .spokenAudio, options: [.allowBluetoothA2DP, .allowAirPlay])
                try session.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                #if DEBUG
                print("❌ Failed to configure audio session: \(error.localizedDescription)")
                #endif
            }
        }
    }

    @MainActor
    public func setupInterruptionHandling(
        onInterruptionBegan: @escaping () -> Void,
        onInterruptionEnded: @escaping () -> Void
    ) {
        if let obs = interruptionObserver {
            NotificationCenter.default.removeObserver(obs)
            interruptionObserver = nil
        }

        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { notification in
            guard let typeRaw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeRaw)
            else { return }

            switch type {
            case .began:
                onInterruptionBegan()
            case .ended:
                let optionsRaw = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsRaw ?? 0)
                if options.contains(.shouldResume) {
                    onInterruptionEnded()
                }
            @unknown default: break
            }
        }
    }

    deinit {
        if let obs = interruptionObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}
#else
public final class AudioSessionManager: @unchecked Sendable {
    public static let shared = AudioSessionManager()
    private init() {}
    public func configureAudioSession() {}
    public func setupInterruptionHandling(onInterruptionBegan: @escaping () -> Void, onInterruptionEnded: @escaping () -> Void) {}
}
#endif
