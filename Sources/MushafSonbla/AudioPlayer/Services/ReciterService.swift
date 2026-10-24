//
//  ReciterService.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class ReciterService: ObservableObject {
    public static let shared = ReciterService()
    
    public struct ReciterInfo: Identifiable, Equatable, Codable, Sendable {
        public let id: Int
        public let nameArabic: String
        public let nameEnglish: String
        public let rewaya: String
        public let folderURL: String
        public let timingSource: TimingSource
        
        public init(id: Int, nameArabic: String, nameEnglish: String, rewaya: String, folderURL: String, timingSource: TimingSource) {
            self.id = id
            self.nameArabic = nameArabic
            self.nameEnglish = nameEnglish
            self.rewaya = rewaya
            self.folderURL = folderURL
            self.timingSource = timingSource
        }
        
        public var displayName: String {
            return nameArabic
        }
        
        public var audioBaseURL: URL? {
            URL(string: folderURL)
        }
    }
    
    @Published public private(set) var availableReciters: [ReciterInfo] = []
    
    @Published public var selectedReciter: ReciterInfo? {
        didSet {
            if let reciter = selectedReciter {
                savedReciterId = reciter.id
            }
        }
    }
    
    @Published public private(set) var isLoading: Bool = true
    
    private var savedReciterId: Int {
        get {
            UserDefaults.standard.integer(forKey: "mushaf_selected_reciter_id")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "mushaf_selected_reciter_id")
        }
    }
    
    private init() {
        loadAvailableRecitersSync()
    }
    
    private struct ReciterManifestEntry: Codable {
        let id: Int
    }
    
    private func loadReciterIdsFromManifest() -> [Int] {
        var url = Bundle.module.url(forResource: "reciters_manifest", withExtension: "json")
        if url == nil {
            url = Bundle.main.url(forResource: "reciters_manifest", withExtension: "json")
        }
        
        guard let manifestURL = url else {
            return ReciterDataProvider.reciters.map { $0.id }
        }
        
        do {
            let data = try Data(contentsOf: manifestURL)
            let entries = try JSONDecoder().decode([ReciterManifestEntry].self, from: data)
            return entries.map { $0.id }
        } catch {
            return ReciterDataProvider.reciters.map { $0.id }
        }
    }
    
    private func loadAvailableRecitersSync() {
        var reciters: [ReciterInfo] = []
        let reciterIds = loadReciterIdsFromManifest()
        
        for id in reciterIds {
            if let entry = ReciterDataProvider.reciters.first(where: { $0.id == id }) {
                let info = ReciterInfo(
                    id: entry.id,
                    nameArabic: entry.nameArabic,
                    nameEnglish: entry.nameEnglish,
                    rewaya: entry.rewaya,
                    folderURL: entry.folderURL,
                    timingSource: entry.timingSource
                )
                reciters.append(info)
            } else if let reciterTiming = AyahTimingService.shared.getReciter(id: id) {
                let info = ReciterInfo(
                    id: reciterTiming.id,
                    nameArabic: reciterTiming.name,
                    nameEnglish: reciterTiming.name_en,
                    rewaya: reciterTiming.rewaya,
                    folderURL: reciterTiming.folder_url,
                    timingSource: .mp3quran
                )
                reciters.append(info)
            }
        }
        
        reciters.sort { $0.nameArabic.localizedStandardCompare($1.nameArabic) == .orderedAscending }
        self.availableReciters = reciters
        
        if savedReciterId > 0, let saved = reciters.first(where: { $0.id == savedReciterId }) {
            self.selectedReciter = saved
        } else if let firstReciter = reciters.first {
            self.selectedReciter = firstReciter
            self.savedReciterId = firstReciter.id
        }
        
        self.isLoading = false
    }
    
    public func selectReciter(_ reciter: ReciterInfo) {
        selectedReciter = reciter
    }
    
    public func getReciterById(_ id: Int) -> ReciterInfo? {
        return availableReciters.first(where: { $0.id == id })
    }
    
    public func getCurrentReciterBaseURL() -> URL? {
        return selectedReciter?.audioBaseURL
    }
}
