//
//  QuranShow.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 20/08/1447 AH.
//

import SwiftUI
import UIKit
import ObjectiveC

public struct QuranThemeHelper {
    public static func backgroundColor(for theme: String) -> Color {
        switch theme {
        case "كريمي": return Color(red: 247/255, green: 243/255, blue: 227/255)
        case "ليلي": return Color.twNeutral900
        default: return .white
        }
    }
    
    public static func foregroundColor(for theme: String) -> Color {
        return theme == "ليلي" ? .white : .twNeutral800
    }
    
    public static func secondaryTextColor(for theme: String) -> Color {
        return theme == "ليلي" ? .gray : .twNeutral500
    }
    
    public static func statusBarStyle(for theme: String) -> UIStatusBarStyle {
        theme == "ليلي" ? .lightContent : .darkContent
    }
}

@MainActor
public enum QuranThemeAppearanceManager {
    private static let subclassPrefix = "SonblaQuranTheme_"
    nonisolated(unsafe) private static var currentStatusBarStyleRaw: Int = UIStatusBarStyle.default.rawValue

    public static func apply(theme: String) {
        let isDark = (theme == "ليلي")
        let style = QuranThemeHelper.statusBarStyle(for: theme)
        currentStatusBarStyleRaw = style.rawValue

        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap(\.windows)
        
        for window in windows {
            window.overrideUserInterfaceStyle = isDark ? .dark : .light
        }

        let rootControllers = windows.compactMap(\.rootViewController)
        for root in rootControllers {
            injectStatusBarStyle(into: root)
            UIView.animate(withDuration: 0.25) {
                root.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    public static func restoreDefault() {
        currentStatusBarStyleRaw = UIStatusBarStyle.default.rawValue
        
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap(\.windows)
        
        for window in windows {
            window.overrideUserInterfaceStyle = .unspecified
        }
        
        for root in windows.compactMap(\.rootViewController) {
            UIView.animate(withDuration: 0.25) {
                root.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    private static func injectStatusBarStyle(into root: UIViewController) {
        let currentClass: AnyClass = type(of: root)
        let className = NSStringFromClass(currentClass)
        guard !className.hasPrefix(subclassPrefix) else { return }

        let targetSubclassName = subclassPrefix + className
        let targetSubclass: AnyClass

        if let existingClass = NSClassFromString(targetSubclassName) {
            targetSubclass = existingClass
        } else {
            guard let newClass = objc_allocateClassPair(currentClass, targetSubclassName, 0) else { return }

            let getterImplementation: @convention(block) (AnyObject) -> Int = { _ in currentStatusBarStyleRaw }
            let imp = imp_implementationWithBlock(getterImplementation)
            let selector = #selector(getter: UIViewController.preferredStatusBarStyle)
            class_addMethod(newClass, selector, imp, "q@:")

            objc_registerClassPair(newClass)
            targetSubclass = newClass
        }

        object_setClass(root, targetSubclass)
    }
}

public extension View {
    func syncQuranThemeAppearance(theme: String) -> some View {
        self
            .onAppear {
                QuranThemeAppearanceManager.apply(theme: theme)
            }
            .onChange(of: theme) { _, newTheme in
                QuranThemeAppearanceManager.apply(theme: newTheme)
            }
    }
    
    func quranSheetBackground(theme: String) -> some View {
        self.presentationBackground {
            QuranThemeHelper.backgroundColor(for: theme)
        }
    }
}

public struct QuranShow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Bindable private var audioPlayer = QuranPlayerCoordinator.shared.mainPlayer
    @State private var viewModel = QuranViewModel()
    
    @State private var showSettingsSheet = false
    @State private var showGuideSheet = false
    @State private var showPlayerSheet = false
    
    @State private var scrollPosition: Int?
    @State private var isTaskStarted = false
    @State public var isBannerVisible = false
    
    @State private var bannerTask: Task<Void, Never>? = nil
    @State private var pageSettleTask: Task<Void, Never>? = nil
    @State private var audioSyncTask: Task<Void, Never>? = nil
    @State private var playActionTask: Task<Void, Never>? = nil
    
    @AppStorage("quranTheme") private var quranTheme: String = "أبيض"
    @AppStorage("hasShownQuranGuide") private var hasShownQuranGuide: Bool = false
    
    private var statusBarScheme: ColorScheme {
        quranTheme == "ليلي" ? .dark : .light
    }
    
    public let searchQuery: String
    public let targetAyaNo: Int?
    public let targetSuraNo: Int?
    public let khatmaId: String?
    public let targetPageId: Int?
    private let initialSuraNo: Int?
    private let initialPageId: Int?
    
    public var onPageRead: ((Int) -> Void)? = nil
    public var onTargetReached: ((Int) -> Void)? = nil
    
    public init(
        suraNo: Int? = nil,
        pageId: Int? = nil,
        targetAyaNo: Int? = nil,
        targetSuraNo: Int? = nil,
        khatmaId: String? = nil,
        targetPageId: Int? = nil,
        searchQuery: String = "",
        onPageRead: ((Int) -> Void)? = nil,
        onTargetReached: ((Int) -> Void)? = nil
    ) {
        self.initialSuraNo = suraNo
        self.initialPageId = pageId
        self.targetAyaNo = targetAyaNo
        self.targetSuraNo = targetSuraNo
        self.khatmaId = khatmaId
        self.targetPageId = targetPageId
        self.searchQuery = searchQuery
        self.onPageRead = onPageRead
        self.onTargetReached = onTargetReached
        
        var startPage = 1
        if let pageId = pageId, pageId >= 1 && pageId <= 604 {
            startPage = pageId
        }
        
        _scrollPosition = State(initialValue: startPage)
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let isSpread = (UIDevice.current.userInterfaceIdiom == .pad && isLandscape) ||
                           (UIDevice.current.userInterfaceIdiom == .phone && isLandscape && (horizontalSizeClass == .regular || geo.size.width > 800))
            
            ZStack {
                QuranThemeHelper
                    .backgroundColor(for: quranTheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.isLoading && viewModel.loadedPages.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        mainScrollView(isSpread: isSpread)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                VStack {
                    CompletionBannerView(isPresented: $isBannerVisible)
                    Spacer()
                }
                .zIndex(100)
            }
            .onChange(of: isSpread) { _, newValue in
                viewModel.isTwoPageMode = newValue
                if newValue, let current = scrollPosition {
                    if current % 2 == 0 {
                        scrollPosition = max(1, current - 1)
                    }
                }
            }
            .onAppear {
                viewModel.isTwoPageMode = isSpread
            }
        }
        .syncQuranThemeAppearance(theme: quranTheme)
        .toolbarColorScheme(statusBarScheme, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ControlGroup {
                    Button {
                        if audioPlayer.isPlaying {
                            showPlayerSheet = true
                        } else {
                            handlePlayButtonTapped()
                        }
                    } label: {
                        Image(systemName: audioPlayer.isPlaying ? "waveform" : "play")
                            .font(.system(size: 16, weight: .medium))
                            .symbolEffect(.variableColor.iterative, isActive: audioPlayer.isPlaying)
                    }
                    
                    Button {
                        showSettingsSheet = true
                    } label: {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                ControlGroup {
                    Button {
                        showGuideSheet = true
                    } label: {
                        Image(systemName: "questionmark")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .environment(\.layoutDirection, .rightToLeft)
        .sheet(isPresented: $showPlayerSheet) {
            QuranPlayer(
                viewModel: audioPlayer,
                onPreviousVerse: { _ = audioPlayer.seekToPreviousVerse() },
                onNextVerse: { _ = audioPlayer.seekToNextVerse() }
            )
            .presentationDetents([.fraction(0.42)])
            .quranSheetBackground(theme: quranTheme)
        }
        .sheet(isPresented: $showSettingsSheet) {
            QuranSettingsSheet()
                .presentationDetents([.fraction(0.42)])
                .quranSheetBackground(theme: quranTheme)
        }
        .sheet(isPresented: $showGuideSheet) {
            QuranGuideSheet()
                .presentationDetents([.large])
                .quranSheetBackground(theme: quranTheme)
        }
        .task {
            await initializeSession()
            
            if !hasShownQuranGuide {
                showGuideSheet = true
                hasShownQuranGuide = true
            }
            
            if let startPage = scrollPosition {
                onPageRead?(startPage)
            }
        }
        .onAppear {
            QuranPlayerCoordinator.shared.isInQuranShow = true
        }
        .onDisappear {
            QuranPlayerCoordinator.shared.isInQuranShow = false
            QuranThemeAppearanceManager.restoreDefault()
            
            bannerTask?.cancel()
            bannerTask = nil
            pageSettleTask?.cancel()
            pageSettleTask = nil
            audioSyncTask?.cancel()
            audioSyncTask = nil
            playActionTask?.cancel()
            playActionTask = nil
            
            viewModel.saveProgress()
            viewModel.cancelAllTasks()
        }
        .onChange(of: audioPlayer.currentVerseNumber) { _, newAya in
            guard let ayaNo = newAya else { return }
            let suraNo = audioPlayer.chapterNumber
            
            audioSyncTask?.cancel()
            audioSyncTask = Task { @MainActor in
                guard let page = try? await QuranDB.shared.getPageForVerse(suraNo: suraNo, ayaNo: ayaNo) else { return }
                guard !Task.isCancelled else { return }
                
                let targetPage = viewModel.isTwoPageMode ? (page % 2 == 0 ? page - 1 : page) : page
                
                if scrollPosition != targetPage {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        scrollPosition = targetPage
                    }
                }
            }
        }
    }
    
    private func mainScrollView(isSpread: Bool) -> some View {
        let pages = isSpread ? Array(stride(from: 1, through: 604, by: 2)) : Array(1...604)
        
        return TabView(selection: $scrollPosition) {
            ForEach(pages, id: \.self) { pageNum in
                if isSpread {
                    spreadContent(for: pageNum)
                        .tag(pageNum)
                } else {
                    pageContent(for: pageNum)
                        .tag(pageNum)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .indexViewStyle(.page(backgroundDisplayMode: .never))
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .onChange(of: scrollPosition) { _, newPage in
            guard let newPage, newPage != viewModel.pageId else { return }
            
            viewModel.pageId = newPage
            
            pageSettleTask?.cancel()
            pageSettleTask = Task(priority: .userInitiated) { @MainActor in
                await viewModel.jumpToPage(pageID: newPage)
                
                try? await Task.sleep(for: .seconds(1.0))
                guard !Task.isCancelled else { return }
                
                onPageRead?(newPage)
                if isSpread && newPage + 1 <= 604 {
                    onPageRead?(newPage + 1)
                }
            }
        }
    }
    
    @ViewBuilder
    private func spreadContent(for rightPageNum: Int) -> some View {
        HStack(spacing: 12) {
            pageContent(for: rightPageNum)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if rightPageNum + 1 <= 604 {
                pageContent(for: rightPageNum + 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder
    private func pageContent(for pageNum: Int) -> some View {
        let isTargetPage = (pageNum == scrollPosition || pageNum == initialPageId)
        let currentTargetAyaNo = isTargetPage ? targetAyaNo : nil
        let currentTargetSuraNo = isTargetPage ? targetSuraNo : nil
        
        let playingSuraNo = audioPlayer.isPlaying ? audioPlayer.chapterNumber : nil
        let playingAyaNo = audioPlayer.isPlaying ? audioPlayer.currentVerseNumber : nil
        
        PageContainer(
            pageNumber: pageNum,
            viewModel: viewModel,
            targetAyaNo: currentTargetAyaNo,
            targetSuraNo: currentTargetSuraNo,
            playingSuraNo: playingSuraNo,
            playingAyaNo: playingAyaNo,
            onPlayVerse: { verse in
                startPlayback(for: verse)
            }
        )
        .id("\(pageNum)-\(playingAyaNo ?? 0)")
    }
    
    private func initializeSession() async {
        guard !isTaskStarted else { return }
        isTaskStarted = true
        
        if let targetPage = initialPageId, targetPage >= 1 && targetPage <= 604 {
            if let suraNo = initialSuraNo {
                viewModel.currentSuraNo = suraNo
                viewModel.autoScrollTarget = suraNo
            }
            await viewModel.jumpToPage(pageID: targetPage)
            scrollPosition = viewModel.isTwoPageMode ? (targetPage % 2 == 0 ? targetPage - 1 : targetPage) : targetPage
        } else if let suraNo = initialSuraNo {
            await viewModel.loadSura(suraNo)
            let pg = viewModel.pageId
            scrollPosition = viewModel.isTwoPageMode ? (pg % 2 == 0 ? pg - 1 : pg) : pg
        } 
        
        if let targetAyaNo {
            viewModel.selectedVerseId = targetAyaNo
        }
    }
    
    private func playCurrentPage() {
        let currentPage = scrollPosition ?? viewModel.pageId
        if let pageData = viewModel.loadedPages[currentPage],
           let firstAyah = pageData.ayahs.first {
            startPlayback(for: firstAyah)
        } else {
            Task { @MainActor in
                if let ayahs = try? await QuranDB.shared.getAyahsByPage(pageId: currentPage),
                   let firstAyah = ayahs.first {
                    startPlayback(for: firstAyah)
                }
            }
        }
    }
    
    private func handlePlayButtonTapped() {
        let currentPage = scrollPosition ?? viewModel.pageId
        
        playActionTask?.cancel()
        playActionTask = Task { @MainActor in
            var isPlayerOnCurrentPage = false
            
            if audioPlayer.hasValidConfiguration, let currentAya = audioPlayer.currentVerseNumber {
                let playerSura = audioPlayer.chapterNumber
                if let playerPage = try? await QuranDB.shared.getPageForVerse(suraNo: playerSura, ayaNo: currentAya) {
                    if viewModel.isTwoPageMode {
                        isPlayerOnCurrentPage = (playerPage == currentPage || playerPage == currentPage + 1)
                    } else {
                        isPlayerOnCurrentPage = (playerPage == currentPage)
                    }
                }
            }
            
            guard !Task.isCancelled else { return }
            
            if isPlayerOnCurrentPage {
                withAnimation { showPlayerSheet = true }
                audioPlayer.startIfNeeded(autoPlay: true)
            } else {
                playCurrentPage()
            }
        }
    }
    
    private func startPlayback(for verse: Ayah) {
        let activeReciterName = audioPlayer.reciterName
        var targetReciter: ReciterService.ReciterInfo? = nil
        
        if !activeReciterName.isEmpty,
           let active = ReciterService.shared.availableReciters.first(where: { $0.nameArabic == activeReciterName || $0.displayName == activeReciterName }) {
            targetReciter = active
        } else {
            targetReciter = ReciterService.shared.selectedReciter ?? ReciterService.shared.availableReciters.first
        }
        
        guard let reciter = targetReciter, let audioURL = reciter.audioBaseURL else { return }
        
        audioPlayer.configureIfNeeded(
            baseURL: audioURL,
            chapterNumber: verse.suraNo,
            chapterName: verse.suraNameAr,
            reciterName: reciter.displayName,
            reciterId: reciter.id,
            timingSource: reciter.timingSource
        )
        audioPlayer.setPreviewVerse(verse.ayaNo)
        QuranPlayerCoordinator.shared.activatePlayer()
        
        withAnimation { showPlayerSheet = true }
        audioPlayer.startIfNeeded(autoPlay: true)
    }
}

public struct CompletionBannerView: View {
    @Binding var isPresented: Bool
    @AppStorage("quranTheme") private var quranTheme: String = "أبيض"
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .twEmerald600],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce, value: isPresented)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("تقبل الله أعمالـــــكم!")
                    .font(.custom("TheYearofHandicrafts-Bold", size: 16))
                    .foregroundStyle(quranTheme == "ليلي" ? .white : .twNeutral800)
                
                Text("لقد أتممت وردك القرآني لهذا اليوم بنجاح.")
                    .font(.custom("TheYearofHandicrafts-SemiBold", size: 12))
                    .foregroundStyle(quranTheme == "ليلي" ? .twNeutral400 : .twNeutral600)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                if quranTheme == "ليلي" {
                    Color.twNeutral800.opacity(0.92)
                } else {
                    Color.white.opacity(0.92)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.twEmerald600.opacity(0.5), .clear, .twEmerald600.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .twEmerald600.opacity(0.15), radius: 12, x: 0, y: 6)
        .shadow(color: .black.opacity(quranTheme == "ليلي" ? 0.3 : 0.08), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .environment(\.layoutDirection, .rightToLeft)
        .offset(y: isPresented ? 0 : -140)
        .opacity(isPresented ? 1.0 : 0.0)
        .allowsHitTesting(isPresented)
    }
}

#Preview {
    QuranShow(pageId: 604)
}
