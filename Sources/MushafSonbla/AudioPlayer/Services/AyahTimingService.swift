//
//  AyahTimingService.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation
import SwiftUI

@MainActor
public final class AyahTimingService {
    public static let shared = AyahTimingService()
    
    private var reciterTimings: [Int: ReciterTiming] = [:]
    private var timingMaps: [Int: [Int: [Int: (start: Int, end: Int)]]] = [:]
    private var attemptedLocalTimingLoads: Set<Int> = []
    
    private init() {}
    
    private func loadTiming(for reciterId: Int) {
        if reciterTimings[reciterId] != nil || attemptedLocalTimingLoads.contains(reciterId) { return }
        attemptedLocalTimingLoads.insert(reciterId)
        
        let fileName = "read_\(reciterId)"
        
        var url: URL? = Bundle.module.url(forResource: fileName, withExtension: "json", subdirectory: "ayah_timing")
        if url == nil {
            url = Bundle.module.url(forResource: fileName, withExtension: "json")
        }
        if url == nil {
            url = Bundle.main.url(forResource: fileName, withExtension: "json", subdirectory: "ayah_timing") ??
                  Bundle.main.url(forResource: fileName, withExtension: "json")
        }
        
        if let url = url {
            do {
                let data = try Data(contentsOf: url)
                let reciter = try JSONDecoder().decode(ReciterTiming.self, from: data)
                reciterTimings[reciterId] = reciter
                
                var map: [Int: [Int: (Int, Int)]] = [:]
                for chapter in reciter.chapters {
                    var chapterMap: [Int: (Int, Int)] = [:]
                    for timing in chapter.aya_timing {
                        chapterMap[timing.ayah] = (timing.start_time, timing.end_time)
                    }
                    map[chapter.id] = chapterMap
                }
                
                timingMaps[reciterId] = map
                #if DEBUG
                print("✅ AyahTimingService: Loaded timings for reciter \(reciterId)")
                #endif
            } catch {
                #if DEBUG
                print("❌ AyahTimingService: Error decoding \(fileName).json: \(error)")
                #endif
            }
        } else {
            #if DEBUG
            print("⚠️ AyahTimingService: Could not find \(fileName).json")
            #endif
        }
    }
    
    public func getTiming(for reciterId: Int, surahId: Int, ayahId: Int) -> (start: Int, end: Int)? {
        loadTiming(for: reciterId)
        return timingMaps[reciterId]?[surahId]?[ayahId]
    }

    public func getReciter(id: Int) -> ReciterTiming? {
        loadTiming(for: id)
        return reciterTimings[id]
    }
    
    public func getAllAvailableReciters() -> [ReciterTiming] {
        let reciterIds = [1, 5, 9, 10, 31, 32, 51, 53, 60, 62, 67, 74, 78, 106, 112, 118, 159, 256]
        var reciters: [ReciterTiming] = []
        for id in reciterIds {
            if let reciter = getReciter(id: id) {
                reciters.append(reciter)
            }
        }
        return reciters
    }
    
    public func getCurrentVerse(for reciterId: Int, surahId: Int, currentTimeMs: Int) -> Int? {
        loadTiming(for: reciterId)
        guard let chapterMap = timingMaps[reciterId]?[surahId], !chapterMap.isEmpty else { return nil }
        
        let timings = chapterMap.map { (ayah: $0.key, start: $0.value.start, end: $0.value.end) }
        let startTimeCorrectionMs = 10
        
        for timing in timings.sorted(by: { $0.start > $1.start }) {
            let adjustedStart = max(0, timing.start - startTimeCorrectionMs)
            if currentTimeMs >= adjustedStart && currentTimeMs <= timing.end {
                return timing.ayah
            }
        }
        
        if let lastVerse = timings.max(by: { $0.end < $1.end }), currentTimeMs > lastVerse.end {
            return lastVerse.ayah
        }
        return nil
    }
    
    public func getChapterTimings(for reciterId: Int, surahId: Int) -> [(ayah: Int, start: Int, end: Int)]? {
        loadTiming(for: reciterId)
        guard let chapterMap = timingMaps[reciterId]?[surahId], !chapterMap.isEmpty else { return nil }
        return chapterMap.map { (ayah: $0.key, start: $0.value.start, end: $0.value.end) }.sorted { $0.ayah < $1.ayah }
    }
}
