//
//  PageContainer.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI

public struct PageContainer: View {
    @Bindable var viewModel: QuranViewModel
    
    public let pageNumber: Int
    public let targetAyaNo: Int?
    public let targetSuraNo: Int?
    
    public var playingSuraNo: Int?
    public var playingAyaNo: Int?
    public var onPlayVerse: ((Ayah) -> Void)?
    
    @State private var pageData: Page?
    @State private var hizbInfo: HizbDisplayInfo?
    @State private var searchTargetVerse: Ayah? = nil
    
    private static var pageCache: [Int: Page] = [:]
    private static var hizbCache: [Int: HizbDisplayInfo?] = [:]
    
    public init(
        pageNumber: Int,
        viewModel: QuranViewModel,
        targetAyaNo: Int? = nil,
        targetSuraNo: Int? = nil,
        playingSuraNo: Int? = nil,
        playingAyaNo: Int? = nil,
        onPlayVerse: ((Ayah) -> Void)? = nil
    ) {
        self.pageNumber = pageNumber
        self.viewModel = viewModel
        self.targetAyaNo = targetAyaNo
        self.targetSuraNo = targetSuraNo
        self.playingSuraNo = playingSuraNo
        self.playingAyaNo = playingAyaNo
        self.onPlayVerse = onPlayVerse
    }
    
    public var body: some View {
        ZStack {
            if let page = pageData {
                QuranPageView<AnyView, AnyView>(
                    pageNumber: pageNumber,
                    page: page,
                    initialHighlightedVerse: searchTargetVerse,
                    selectedVerse: $viewModel.selectedVerse,
                    playingSuraNo: playingSuraNo,
                    playingAyaNo: playingAyaNo,
                    onVerseLongPress: { verse in
                        viewModel.showVerseDetails(verse)
                    },
                    header: {
                        AnyView(
                            PageHeaderView(page: page, hizbInfo: hizbInfo)
                                .frame(height: 20)
                        )
                    },
                    footer: {
                        AnyView(
                            PageFooterView(pageNumber: pageNumber, isRight: page.isRight)
                                .frame(height: 20)
                        )
                    }
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await loadPage()
        }
    }
    
    private func loadPage() async {
        if let cached = Self.pageCache[pageNumber] {
            await MainActor.run {
                self.pageData = cached
                if let cachedHizb = Self.hizbCache[pageNumber] {
                    self.hizbInfo = cachedHizb
                }
                
                if self.viewModel.loadedPages[self.pageNumber] == nil, let first = cached.verses1441.first {
                    self.viewModel.loadedPages[self.pageNumber] = CachedPage(
                        ayahs: cached.verses1441,
                        suraNameAr: first.suraNameAr,
                        partId: first.partId,
                        suraNo: first.suraNo,
                        suraFirstPage: first.ayaNo == 1
                    )
                }
                
                if let targetAya = targetAyaNo {
                    self.searchTargetVerse = cached.verses1441.first { ayah in
                        if let targetSura = targetSuraNo {
                            return ayah.ayaNo == targetAya && ayah.suraNo == targetSura
                        }
                        return ayah.ayaNo == targetAya
                    }
                }
            }
            return
        }
        
        do {
            async let fetchVerses = QuranDB.shared.getAyahsByPage(pageId: pageNumber)
            async let fetchHeaders = QuranDB.shared.getChapterHeadersByPage(pageId: pageNumber)
            async let fetchHizb = QuranDB.shared.getHizbInfoForPage(pageId: pageNumber)
            
            let (verses, headers, hizb) = try await (fetchVerses, fetchHeaders, fetchHizb)
            let newPage = Page(identifier: pageNumber, number: pageNumber, isRight: pageNumber % 2 != 0, verses: verses, headers: headers)
            
            await MainActor.run {
                self.pageData = newPage
                self.hizbInfo = hizb
                Self.pageCache[pageNumber] = newPage
                Self.hizbCache[pageNumber] = hizb
                
                if let first = verses.first {
                    self.viewModel.loadedPages[self.pageNumber] = CachedPage(
                        ayahs: verses,
                        suraNameAr: first.suraNameAr,
                        partId: first.partId,
                        suraNo: first.suraNo,
                        suraFirstPage: first.ayaNo == 1
                    )
                }
                
                if let targetAya = self.targetAyaNo {
                    self.searchTargetVerse = verses.first(where: { ayah in
                        if let targetSura = self.targetSuraNo {
                            return ayah.ayaNo == targetAya && ayah.suraNo == targetSura
                        }
                        return ayah.ayaNo == targetAya
                    })
                }
            }
        } catch {
            #if DEBUG
            print("Error loading page: \(error)")
            #endif
        }
    }
}
