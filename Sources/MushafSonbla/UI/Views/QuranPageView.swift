//
//  QuranPageView.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 09/12/1447 AH.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

public struct SelectedVerseRectKey: PreferenceKey {
    public nonisolated(unsafe) static var defaultValue: CGRect? = nil
    public static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        guard let newRect = nextValue() else { return }
        if let current = value {
            value = newRect.minY < current.minY ? newRect : current
        } else {
            value = newRect
        }
    }
}

public struct QuranPageView<Header: View, Footer: View>: View {
    public let pageNumber: Int
    public var page: Page
    public let initialHighlightedVerse: Ayah?
    @Binding public var selectedVerse: Ayah?
    
    public let playingSuraNo: Int?
    public let playingAyaNo: Int?
    
    public var onVerseLongPress: ((Ayah) -> Void)? = nil
    public var onTapPage: (() -> Void)? = nil
    
    private let headerBuilder: () -> Header
    private let footerBuilder: () -> Footer
    
    @State private var pressingVerseID: Int? = nil
    @State private var temporarySearchHighlightID: Int? = nil
    @State private var activeActionAyah: Ayah? = nil
    
    public init(
        pageNumber: Int,
        page: Page,
        initialHighlightedVerse: Ayah?,
        selectedVerse: Binding<Ayah?>,
        playingSuraNo: Int? = nil,
        playingAyaNo: Int? = nil,
        onVerseLongPress: ((Ayah) -> Void)? = nil,
        onTapPage: (() -> Void)? = nil,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.pageNumber = pageNumber
        self.page = page
        self.initialHighlightedVerse = initialHighlightedVerse
        self._selectedVerse = selectedVerse
        self.playingSuraNo = playingSuraNo
        self.playingAyaNo = playingAyaNo
        self.onVerseLongPress = onVerseLongPress
        self.onTapPage = onTapPage
        self.headerBuilder = header
        self.footerBuilder = footer
    }
    
    public var body: some View {
        GeometryReader { reader in
            let availableWidth = reader.size.width
            let availableHeight = reader.size.height
            let isLandscape = availableWidth > availableHeight
            
            let headerFooterPadding: CGFloat = isLandscape ? 80 : 120
            let remainingHeight = availableHeight - headerFooterPadding
            let lineHeight = remainingHeight / 15.0
            
            VStack(spacing: 0) {
                headerBuilder()
                    .padding(.top, isLandscape ? 0 : 10)
                    .padding(.bottom, 24)
                
                VStack(spacing: 0) {
                    ForEach(0...14, id: \.self) { line in
                        let isNextLineAChapterHeader = page.chapterHeaders1441.contains(where: { $0.line == (line + 1) })
                        
                        LineImageView(
                            pageNumber: pageNumber,
                            chapterheader: Array(page.chapterHeaders1441),
                            line: line,
                            verses: Array(page.verses1441),
                            container: CGSize(width: availableWidth, height: lineHeight),
                            selectedVerseID: selectedVerse?.id,
                            highlightedVerseID: initialHighlightedVerse?.id,
                            temporarySearchHighlightID: temporarySearchHighlightID,
                            playingSuraNo: playingSuraNo,
                            playingAyaNo: playingAyaNo,
                            pressingVerseID: pressingVerseID,
                            onPressingChange: { id in pressingVerseID = id },
                            onTap: { verse in
                                handleAyahLongPress(verse)
                            },
                            onTapPage: onTapPage
                        )
                        .equatable()
                        .frame(width: availableWidth, height: lineHeight, alignment: .center)
                        .id("\(pageNumber)-\(line)")
                        .padding(.bottom, isNextLineAChapterHeader ? 10 : 0)
                    }
                }
                .frame(width: availableWidth, height: remainingHeight)
                
                Spacer(minLength: 0)
                
                footerBuilder()
                    .padding(.bottom, isLandscape ? 20 : 0)
            }
            .frame(width: availableWidth, height: availableHeight)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear { triggerSearchHighlight(for: initialHighlightedVerse?.id) }
        .onChange(of: initialHighlightedVerse?.id) { _, newId in triggerSearchHighlight(for: newId) }
        .sheet(item: $activeActionAyah) { verse in
            AyahActionSheet(verse: verse)
        }
        .onChange(of: activeActionAyah) { _, newValue in
            if newValue == nil {
                selectedVerse = nil
            }
        }
    }
    
    private func handleAyahLongPress(_ verse: Ayah) {
        withAnimation {
            selectedVerse = verse
            
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            
            onVerseLongPress?(verse)
            activeActionAyah = verse
        }
    }
    
    private func triggerSearchHighlight(for id: Int?) {
        guard let id = id else { return }
        temporarySearchHighlightID = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                if temporarySearchHighlightID == id { temporarySearchHighlightID = nil }
            }
        }
    }
}

private struct LineImageView: View, Equatable {
    let pageNumber: Int
    let chapterheader: [ChapterHeader]
    let line: Int
    let verses: [Ayah]
    let container: CGSize
    let selectedVerseID: Int?
    let highlightedVerseID: Int?
    let temporarySearchHighlightID: Int?
    
    let playingSuraNo: Int?
    let playingAyaNo: Int?
    
    let pressingVerseID: Int?
    
    var onPressingChange: (Int?) -> Void
    var onTap: (Ayah) -> Void
    var onTapPage: (() -> Void)?
    
    @AppStorage("quranTheme") private var quranTheme: String = "أبيض"
    
    static func == (lhs: LineImageView, rhs: LineImageView) -> Bool {
        lhs.pageNumber == rhs.pageNumber &&
        lhs.line == rhs.line &&
        lhs.container == rhs.container &&
        lhs.selectedVerseID == rhs.selectedVerseID &&
        lhs.highlightedVerseID == rhs.highlightedVerseID &&
        lhs.temporarySearchHighlightID == rhs.temporarySearchHighlightID &&
        lhs.playingSuraNo == rhs.playingSuraNo &&
        lhs.playingAyaNo == rhs.playingAyaNo &&
        lhs.pressingVerseID == rhs.pressingVerseID &&
        lhs.quranTheme == rhs.quranTheme
    }
    
    private let originalLineSize = CGSize(width: 1440, height: 232)
    @State private var pressTask: Task<Void, Never>? = nil
    
    private func shouldHighlight(_ verse: Ayah) -> Bool {
        let isPlaying = (playingSuraNo == verse.suraNo && playingAyaNo == verse.ayaNo)
        return selectedVerseID == verse.id ||
        temporarySearchHighlightID == verse.id ||
        pressingVerseID == verse.id ||
        isPlaying
    }
    
    private var highlightColor: Color {
        return self.quranTheme == "ليلي"
        ? Color(red: 1/255, green: 92/255, blue: 66/255)
        : Color(red: 184/255, green: 240/255, blue: 119/255)
    }
    
    #if canImport(UIKit)
    var selectedCorners: UIRectCorner { return [.allCorners] }
    #endif

    private func verseHighlightsView(verse: Ayah, geometry: GeometryProxy) -> some View {
        ForEach(verse.highlights1441.filter({ $0.line == line }), id: \.self) { highlight in
            let visualLeftX = geometry.size.width * CGFloat(1.0 - highlight.right)
            let visualRightX = geometry.size.width * CGFloat(1.0 - highlight.left)
            
            let highlightWidth = visualRightX - visualLeftX
            let highlightHeight = geometry.size.height * 0.94
            
            Rectangle()
                .fill(shouldHighlight(verse) ? highlightColor : .clear)
                .id("\(highlight.id)-\(quranTheme)")
                .frame(width: highlightWidth, height: highlightHeight)
                .contentShape(Rectangle())
                .supportDoubleTapBookmark(
                    verseID: verse.id,
                    suraNumber: verse.suraNo,
                    ayahNumber: verse.ayaNo
                )
                #if canImport(UIKit)
                .cornerRadius(8, corners: selectedCorners)
                #else
                .cornerRadius(8)
                #endif
                .onLongPressGesture(minimumDuration: 0.4, pressing: { isPressing in
                    if isPressing {
                        pressTask?.cancel()
                        let verseID = verse.id
                        pressTask = Task {
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            if !Task.isCancelled {
                                await MainActor.run { onPressingChange(verseID) }
                            }
                        }
                    } else {
                        pressTask?.cancel()
                        pressTask = nil
                        onPressingChange(nil)
                    }
                }, perform: {
                    pressTask?.cancel()
                    pressTask = nil
                    onPressingChange(nil)
                    onTap(verse)
                })
                .position(x: visualLeftX + highlightWidth / 2, y: highlightHeight * 0.8)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: SelectedVerseRectKey.self,
                            value: shouldHighlight(verse) ? proxy.frame(in: .named("MushafRoot")) : nil
                        )
                    }
                )
        }
    }
    
    var body: some View {
        let imageAspect = originalLineSize.width / originalLineSize.height
        let containerWidth = container.width
        
        ZStack {
            Color.clear
                .contentShape(Rectangle())
            
            GeometryReader { geometry in
                let scaledImageHeight = geometry.size.width / imageAspect
                let cropOffset = (scaledImageHeight - geometry.size.height) / 2
                let lineScale = geometry.size.width / originalLineSize.width
                
                ForEach(verses, id: \.id) { verse in
                    verseHighlightsView(verse: verse, geometry: geometry)
                    if let marker = verse.marker1441, marker.line == line {
                        let markerX = geometry.size.width * CGFloat(1.0 - marker.centerX)
                        
                        let fullImageY = scaledImageHeight * CGFloat(marker.centerY)
                        let markerY = fullImageY - cropOffset
                        
                        VerseFasel(number: verse.ayaNo, scale: lineScale)
                            .position(x: markerX, y: markerY + 10)
                            .allowsHitTesting(false)
                    }
                }
                
                ForEach(chapterheader, id: \.self) { chapterheader in
                    let chapterX = geometry.size.width * CGFloat(1.0 - chapterheader.centerX)
                    
                    let fullImageY = scaledImageHeight * CGFloat(chapterheader.centerY)
                    let chapterY = fullImageY - cropOffset
                    
                    if chapterheader.line == line {
                        Image(quranTheme == "ليلي" ? "Sura/suraNameBarDark" : "Sura/suraNameBar", bundle: .module)
                            .resizable()
                            .frame(width: containerWidth * 0.9, height: scaledImageHeight * 0.8)
                            .position(x: chapterX, y: chapterY + 12)
                            .allowsHitTesting(false)
                    }
                }
                
                QuranLineImageView(
                    page: pageNumber,
                    line: line + 1,
                    imageAspect: imageAspect,
                    containerWidth: containerWidth,
                    scaledImageHeight: scaledImageHeight
                )
                .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTapPage?() }
    }
}

#if canImport(UIKit)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
#endif

#if DEBUG
#Preview("iPad أفقي – صفحتان (601)", traits: .landscapeLeft) {
    NavigationStack {
        QuranShow(pageId: 601)
    }
}

#Preview("iPad أفقي – الفاتحة والبقرة", traits: .landscapeLeft) {
    NavigationStack {
        QuranShow(pageId: 106)
    }
}

#Preview("iPad عمودي – صفحة", traits: .portrait) {
    NavigationStack {
        QuranShow(pageId: 601)
    }
}

#endif
