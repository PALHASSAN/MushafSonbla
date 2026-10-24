//
//  QuranPlayerCoordinator.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation
import SwiftUI

@MainActor
@Observable
public final class QuranPlayerCoordinator {
    public static let shared = QuranPlayerCoordinator()
    public var isInQuranShow: Bool = false
    
    public let mainPlayer = QuranPlayerViewModel()
    public var activePlayer: QuranPlayerViewModel?
    
    public var hasActivePlayer: Bool {
        activePlayer?.hasValidConfiguration ?? false
    }
    
    private init() {}
    
    public func activatePlayer() {
        if activePlayer !== mainPlayer {
            activePlayer = mainPlayer
        }
    }
    
    public func dismissPlayer() {
        mainPlayer.stop()
        activePlayer = nil
    }
    
    public func startPlayback(from verse: Ayah) {
        activatePlayer()
        
        let targetReciter = ReciterService.shared.selectedReciter ?? ReciterService.shared.availableReciters.first
        if let reciter = targetReciter, let audioURL = reciter.audioBaseURL {
            _ = mainPlayer.configureIfNeeded(
                baseURL: audioURL,
                chapterNumber: verse.suraNo,
                chapterName: verse.suraNameAr,
                reciterName: reciter.displayName,
                reciterId: reciter.id,
                timingSource: reciter.timingSource
            )
        } else if mainPlayer.chapterNumber != verse.suraNo {
            mainPlayer.updateChapter(number: verse.suraNo, name: verse.suraNameAr)
        }
        
        mainPlayer.seekToVerse(verse.ayaNo)
        
        if !mainPlayer.isPlaying {
            mainPlayer.startIfNeeded(autoPlay: true)
        }
    }
}
