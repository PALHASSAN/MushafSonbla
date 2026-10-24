//
//  QuranShow.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
import ObjectiveC
#endif

// MARK: - Quran Theme & Appearance Helpers

public enum QuranThemeHelper {
    public static func backgroundColor(for theme: String) -> Color {
        if theme == "ليلي" {
            return Color(red: 18/255, green: 18/255, blue: 18/255)
        } else {
            return Color(red: 251/255, green: 249/255, blue: 243/255)
        }
    }
    
    #if canImport(UIKit)
    public static func statusBarStyle(for theme: String) -> UIStatusBarStyle {
        theme == "ليلي" ? .lightContent : .darkContent
    }
    #endif
}

#if canImport(UIKit)
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
#endif

public extension View {
    func syncQuranThemeAppearance(theme: String) -> some View {
        #if canImport(UIKit)
        self
            .onAppear {
                QuranThemeAppearanceManager.apply(theme: theme)
            }
            .onChange(of: theme) { _, newTheme in
                QuranThemeAppearanceManager.apply(theme: newTheme)
            }
        #else
        self
        #endif
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
    
    @State private var viewModel = QuranViewModel()
    
    @State private var showSettingsSheet = false
    @State private var showGuideSheet = false
    @State private var showPlayerSheet = false
    
    @State private var scrollPosition: Int?
    @State private var isTaskStarted = false
    @State public var isBannerVisible = false
    
    @State private var bannerTask: Task<Void, Never>? = nil
    @State private var pageSettleTask: Task<Void, Never>? = nil
    
    @AppStorage("quranTheme") private var quranTheme: String = "أبيض"
    @AppStorage("hasShownQuranGuide") private var hasShownQuranGuide: Bool = false
    
    private var statusBarScheme: ColorScheme {
        quranTheme == "ليلي" ? .dark : .light
    }
    
    public let searchQuery: String
    public let targetAyaNo: Int?
    public let targetSuraNo: Int?
    private let initialSuraNo: Int?
    private let initialPageId: Int?
    
    public var onPageRead: ((Int) -> Void)? = nil
    
    public init(
        suraNo: Int? = nil,
        pageId: Int? = nil,
        targetAyaNo: Int? = nil,
        targetSuraNo: Int? = nil,
        searchQuery: String = "",
        onPageRead: ((Int) -> Void)? = nil
    ) {
        self.initialSuraNo = suraNo
        self.initialPageId = pageId
        self.targetAyaNo = targetAyaNo
        self.targetSuraNo = targetSuraNo
        self.searchQuery = searchQuery
        self.onPageRead = onPageRead
        
        var startPage = 1
        if let pageId = pageId, pageId >= 1 && pageId <= 604 {
            startPage = pageId
        }
        
        _scrollPosition = State(initialValue: startPage)
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            #if canImport(UIKit)
            let isSpread = (UIDevice.current.userInterfaceIdiom == .pad && isLandscape) ||
                           (UIDevice.current.userInterfaceIdiom == .phone && isLandscape && (horizontalSizeClass == .regular || geo.size.width > 800))
            #else
            let isSpread = isLandscape
            #endif
            
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
        .sheet(isPresented: $showSettingsSheet) {
//            QuranSettingsSheet()
            Text("Hello from Settings")
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
        .onDisappear {
            #if canImport(UIKit)
            QuranThemeAppearanceManager.restoreDefault()
            #endif
            
            bannerTask?.cancel()
            bannerTask = nil
            pageSettleTask?.cancel()
            pageSettleTask = nil
            
            viewModel.saveProgress()
            viewModel.cancelAllTasks()
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
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .indexViewStyle(.page(backgroundDisplayMode: .never))
        #endif
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
        PageContainer(
            pageNumber: pageNum,
            viewModel: viewModel
        )
        .id(pageNum)
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
        } else {
            await viewModel.initializeReadingSession()
            let pg = viewModel.pageId
            scrollPosition = viewModel.isTwoPageMode ? (pg % 2 == 0 ? pg - 1 : pg) : pg
        }
        
        if let targetAyaNo {
            viewModel.selectedVerseId = targetAyaNo
        }
    }
}

public struct CompletionBannerView: View {
    @Binding public var isPresented: Bool
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
                        colors: [.green, Color(red: 5/255, green: 150/255, blue: 105/255)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text("تقبل الله أعمالـــــكم!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(quranTheme == "ليلي" ? .white : Color(red: 38/255, green: 38/255, blue: 38/255))
                
                Text("لقد أتممت وردك القرآني لهذا اليوم بنجاح.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(quranTheme == "ليلي" ? Color(red: 163/255, green: 163/255, blue: 163/255) : Color(red: 82/255, green: 82/255, blue: 82/255))
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
                    Color(red: 38/255, green: 38/255, blue: 38/255).opacity(0.92)
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
                        colors: [Color(red: 5/255, green: 150/255, blue: 105/255).opacity(0.5), .clear, Color(red: 5/255, green: 150/255, blue: 105/255).opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color(red: 5/255, green: 150/255, blue: 105/255).opacity(0.15), radius: 12, x: 0, y: 6)
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
