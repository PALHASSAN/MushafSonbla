//
//  QuranViewModel.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//


import SwiftUI
import Observation
import CoreGraphics

#if canImport(UIKit)
import UIKit
#endif

public struct CachedPage: Sendable {
    public let ayahs: [Ayah]
    public let suraNameAr: String
    public let partId: Int
    public let suraNo: Int
    public let suraFirstPage: Bool

    public init(ayahs: [Ayah], suraNameAr: String, partId: Int, suraNo: Int, suraFirstPage: Bool) {
        self.ayahs = ayahs
        self.suraNameAr = suraNameAr
        self.partId = partId
        self.suraNo = suraNo
        self.suraFirstPage = suraFirstPage
    }
}

final class PageWrapper: @unchecked Sendable {
    let page: CachedPage
    init(_ page: CachedPage) { self.page = page }
}


#if canImport(UIKit)
@MainActor
public final class AyahImageCache: Sendable {
    public static let shared = AyahImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() { cache.countLimit = 300 }
    
    public func getImage(for number: Int, theme: String) -> UIImage {
        let cacheKey = "\(number)_\(theme)" as NSString
        if let cached = cache.object(forKey: cacheKey) { return cached }
        
        let isDark = theme == "ليلي"
        let imageName = isDark ? "Sura/ayahNumberDark" : "Sura/ayahNumber"
        
        let size = CGSize(width: 33, height: 33)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UITraitCollection.current.displayScale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { _ in
            if let bgImage = UIImage(named: imageName, in: Bundle.module, with: nil) {
                bgImage.draw(in: CGRect(origin: .zero, size: size))
            }
            
            let text = "\(number.toArabic)"
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let font = UIFont(name: "QuranNumbers", size: 18) ?? UIFont.systemFont(ofSize: 16)
            let textColor = UIColor(named: "twNeutral800", in: Bundle.module, compatibleWith: nil) ?? UIColor.black
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            let stringSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: 0,
                y: ((size.height - stringSize.height) / 2) - 1,
                width: size.width,
                height: stringSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        let finalImage = image.withRenderingMode(.alwaysOriginal)
        cache.setObject(finalImage, forKey: cacheKey)
        return finalImage
    }
}
#endif

@Observable @MainActor
public final class QuranViewModel {
    public var ayahs: [Ayah] = []
    public var isLoading: Bool = false
    public var suraNameAr: String = ""
    public var partId: Int = 0
    public var pageId: Int = 1
    
    public var currentSuraNo: Int = 1
    public var lastSavedSuraNo: Int = 0
    public var lastSavedPageId: Int = 0
    
    public var autoScrollTarget: Int? = nil
    public var loadedPages: [Int: CachedPage] = [:]
    
    public var isTwoPageMode: Bool = false {
        didSet {
            if isTwoPageMode { preloadNeighboringPages(pageId: pageId) }
        }
    }
    
    public var onPageChange: ((Int, Int) -> Void)? // (pageId, suraNo)
    
    private let sessionCache: NSCache<NSNumber, PageWrapper> = {
        let cache = NSCache<NSNumber, PageWrapper>()
        cache.countLimit = 6
        return cache
    }()
    
    private var uniquePagesReadThisSession: Set<Int> = []
    private var loadingTasks: [Int: Task<Void, Never>] = [:]
    private var saveTask: Task<Void, Never>?
    
    #if canImport(UIKit)
    private var memoryWarningTask: Task<Void, Never>?
    #endif
    
    public var selectedVerseId: Int = UserDefaults.standard.integer(forKey: "selected_verse_id") == 0 ? -1 : UserDefaults.standard.integer(forKey: "selected_verse_id") {
        didSet {
            UserDefaults.standard.set(selectedVerseId, forKey: "selected_verse_id")
        }
    }
    
    public var selectedVerse: Ayah? = nil
    public var tafsirVerse: Ayah? = nil
    public var showTafsir: Bool = false
    
    private struct Keys {
        static let lastSuraNo = "LastSuraNo"
        static let lastSuraName = "LastSuraName"
        static let lastPageID = "LastPageID"
        static let lastPartID = "LastPartID"
    }
    
    public init() {
        #if canImport(UIKit)
        memoryWarningTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didReceiveMemoryWarningNotification) {
                self?.handleMemoryWarning()
            }
        }
        #endif
    }
    
    public func cancelAllTasks() {
        #if canImport(UIKit)
        memoryWarningTask?.cancel()
        #endif
        saveTask?.cancel()
        loadingTasks.values.forEach { $0.cancel() }
        loadingTasks.removeAll()
    }
    
    private func handleMemoryWarning() {
        sessionCache.removeAllObjects()
        let current = pageId
        loadedPages.keys.filter { $0 != current }.forEach { loadedPages.removeValue(forKey: $0) }
    }
    
    public func saveProgress() {
        guard pageId != lastSavedPageId || currentSuraNo != lastSavedSuraNo else { return }
        guard currentSuraNo > 0, !suraNameAr.isEmpty else { return }
        
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.5))
            guard let self = self, !Task.isCancelled else { return }
            
            let defaults = UserDefaults.standard
            defaults.set(self.currentSuraNo, forKey: Keys.lastSuraNo)
            defaults.set(self.suraNameAr, forKey: Keys.lastSuraName)
            defaults.set(self.pageId, forKey: Keys.lastPageID)
            defaults.set(self.partId, forKey: Keys.lastPartID)
            
            self.onPageChange?(self.pageId, self.currentSuraNo)
            
            self.lastSavedPageId = self.pageId
            self.lastSavedSuraNo = self.currentSuraNo
        }
    }
    
    public func updateActiveSura(no: Int, name: String) {
        if self.currentSuraNo != no {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            
            withTransaction(transaction) {
                self.currentSuraNo = no
                self.suraNameAr = name
            }
            
            saveProgress()
        }
    }
    
    public func initializeReadingSession(startPage: Int? = nil) async {
        let targetPage: Int
        if let explicitPage = startPage, explicitPage >= 1 {
            targetPage = explicitPage
        } else {
            let defaults = UserDefaults.standard
            let savedPage = defaults.integer(forKey: Keys.lastPageID)
            let savedSuraNo = defaults.integer(forKey: Keys.lastSuraNo)
            self.currentSuraNo = savedSuraNo > 0 ? savedSuraNo : 1
            targetPage = savedPage > 0 ? savedPage : 1
        }
        
        self.lastSavedPageId = targetPage
        self.autoScrollTarget = self.currentSuraNo
        await jumpToPage(pageID: targetPage)
    }
    
    public func jumpToPage(pageID: Int) async {
        guard pageID >= 1 && pageID <= 604 else { return }
        if let cached = getCachedPage(pageID) {
            applyPageData(cached, id: pageID)
            preloadNeighboringPages(pageId: pageID)
            return
        }
        
        isLoading = true
        await loadSpecificPage(pageId: pageID)
        isLoading = false
    }
    
    public func resumeReading(fromSura suraNo: Int, pageId: Int) async {
        self.currentSuraNo = suraNo
        self.autoScrollTarget = suraNo
        await jumpToPage(pageID: pageId)
    }
    
    private func loadSpecificPage(pageId: Int) async {
        cleanupOldTasks(except: pageId)
        loadingTasks[pageId]?.cancel()
        
        loadingTasks[pageId] = Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let ayahs = try await QuranDB.shared.getAyahsByPage(pageId: pageId)
                guard !ayahs.isEmpty, !Task.isCancelled else { return }
                
                let firstAyah = ayahs.first!
                let pageData = CachedPage(
                    ayahs: ayahs,
                    suraNameAr: firstAyah.suraNameAr,
                    partId: firstAyah.partId,
                    suraNo: firstAyah.suraNo,
                    suraFirstPage: firstAyah.ayaNo == 1
                )
                
                if !Task.isCancelled {
                    self.sessionCache.setObject(PageWrapper(pageData), forKey: NSNumber(value: pageId))
                    self.applyPageData(pageData, id: pageId)
                    self.preloadNeighboringPages(pageId: pageId)
                }
            } catch { }
            self.loadingTasks[pageId] = nil
        }
        await loadingTasks[pageId]?.value
    }
    
    private func applyPageData(_ data: CachedPage, id: Int) {
        self.ayahs = data.ayahs
        self.pageId = id
        self.partId = data.partId
        
        if self.autoScrollTarget == nil {
            self.autoScrollTarget = data.suraNo
        }
        
        if let targetSuraAyah = data.ayahs.first(where: { $0.suraNo == self.currentSuraNo }) {
            self.suraNameAr = targetSuraAyah.suraNameAr
        } else {
            self.currentSuraNo = data.suraNo
            self.suraNameAr = data.suraNameAr
        }
        
        self.loadedPages[id] = data
        saveProgress()
    }
    
    private func preloadNeighboringPages(pageId: Int) {
        for targetPageId in [pageId + 1, pageId - 1] {
            guard targetPageId >= 1 && targetPageId <= 604, getCachedPage(targetPageId) == nil, loadingTasks[targetPageId] == nil else { continue }
            
            loadingTasks[targetPageId] = Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let ayahs = try? await QuranDB.shared.getAyahsByPage(pageId: targetPageId), !ayahs.isEmpty, !Task.isCancelled {
                    let first = ayahs.first!
                    let data = CachedPage(ayahs: ayahs, suraNameAr: first.suraNameAr, partId: first.partId, suraNo: first.suraNo, suraFirstPage: first.ayaNo == 1)
                    self.sessionCache.setObject(PageWrapper(data), forKey: NSNumber(value: targetPageId))
                }
                self.loadingTasks[targetPageId] = nil
            }
        }
    }
    
    private func cleanupOldTasks(except currentPageId: Int) {
        let spreadEnd = isTwoPageMode ? min(604, currentPageId + 1) : currentPageId
        let visibleRange = (currentPageId - 1)...(spreadEnd + 1)
        
        loadedPages.keys.filter { !visibleRange.contains($0) }.forEach { loadedPages.removeValue(forKey: $0) }
        loadingTasks.keys.filter { !visibleRange.contains($0) }.forEach {
            loadingTasks[$0]?.cancel()
            loadingTasks.removeValue(forKey: $0)
        }
    }
    
    public func loadSura(_ suraNo: Int) async {
        isLoading = true
        loadingTasks.values.forEach { $0.cancel() }
        loadingTasks.removeAll()
        
        if let startPage = try? await QuranDB.shared.getStartPageForSura(suraNo) {
            self.currentSuraNo = suraNo
            self.autoScrollTarget = suraNo
            await jumpToPage(pageID: startPage)
        }
        isLoading = false
    }
    
    public func getCachedPage(_ id: Int) -> CachedPage? {
        loadedPages[id] ?? sessionCache.object(forKey: NSNumber(value: id))?.page
    }
    
    public func nextPage() async {
        let step = isTwoPageMode ? 2 : 1
        if pageId + step <= 604 {
            await jumpToPage(pageID: pageId + step)
        } else if pageId < 604 {
            await jumpToPage(pageID: 604)
        }
    }
    
    public func previousPage() async {
        let step = isTwoPageMode ? 2 : 1
        if (pageId - step) >= 1 {
            await jumpToPage(pageID: pageId - step)
        } else if pageId > 1 {
            await jumpToPage(pageID: 1)
        }
    }
    
    public func clearSelection() {
        selectedVerse = nil
        selectedVerseId = -1
    }
    
    public func showVerseDetails(_ verse: Ayah) {
        selectedVerse = verse
        selectedVerseId = verse.id
    }
}
