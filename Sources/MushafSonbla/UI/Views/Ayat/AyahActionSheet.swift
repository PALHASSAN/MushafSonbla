//
//  AyahActionSheet.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct AyahActionSheet: View {
    public let verse: Ayah
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @AppStorage("quranTheme") private var quranTheme: String = "أبيض"
    
    @State private var activeBookmarkColorIndex: Int? = nil
    @State private var showReciterPicker = false
    
    private var viewModel: QuranPlayerViewModel {
        QuranPlayerCoordinator.shared.mainPlayer
    }
    
    private var availableColors: [String] {
        BookmarkColor.availableHexes(isDarkTheme: quranTheme == "ليلي")
    }
    
    public init(verse: Ayah) {
        self.verse = verse
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("سورة \(verse.suraNameAr) (\(verse.ayaNo.toArabic))")
                .appFont(size: 20, weight: .bold)
                .foregroundStyle(colorScheme == .light ? .twNeutral800 : .white)
                .entranceTransition(order: 0)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("إضافة فاصل مرجعي")
                    .appFont(size: 15, weight: .bold)
                    .foregroundStyle(colorScheme == .light ? .twNeutral800 : .twNeutral200)
                
                HStack(spacing: 16) {
                    ForEach(Array(availableColors.enumerated()), id: \.offset) { index, hex in
                        let isSelected = activeBookmarkColorIndex == index
                        let color = Color(hex: hex)
                        
                        Button {
#if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
                            saveBookmark(at: index)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.opacity(isSelected ? 0.25 : 0.12))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: isSelected ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 19, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(color)
                                
                                if isSelected {
                                    Circle()
                                        .strokeBorder(color, lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                }
                            }
                        }
                        .buttonStyle(SpatialTouchPressStyle())
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .compositingGroup()
            .entranceTransition(order: 1)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("التلاوة")
                    .appFont(size: 15, weight: .bold)
                    .foregroundStyle(colorScheme == .light ? .twNeutral800 : .twNeutral200)
                
                HStack(spacing: 0) {
                    Button {
                        showReciterPicker.toggle()
                    } label: {
                        HStack(alignment: .center, spacing: 8) {
                            Text(viewModel.reciterName.isEmpty ? "اختر القارئ" : viewModel.reciterName)
                                .appFont(weight: .medium)
                                .foregroundStyle(colorScheme == .light ? .twNeutral700 : .twNeutral300)
                                .lineLimit(1)
                            
                            Spacer(minLength: 0)
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.twNeutral400)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(SpatialTouchPressStyle())
                    
                    Divider()
                        .frame(height: 22)
                        .background(colorScheme == .light ? .twNeutral300 : .twNeutral700)
                    
                    Button {
                        playAyah()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Text("تشغيل")
                                .appFont(size: 15, weight: .bold)
                            
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.twEmerald600)
                        }
                        .foregroundStyle(colorScheme == .light ? .twNeutral800 : .twNeutral200)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(SpatialTouchPressStyle())
                    .disabled(viewModel.reciterName.isEmpty)
                    .opacity(viewModel.reciterName.isEmpty ? 0.45 : 1.0)
                }
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(colorScheme == .light ? .black.opacity(0.04) : .white.opacity(0.06))
                )
            }
            .compositingGroup()
            .entranceTransition(order: 2)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .glowBackground()
        .environment(\.layoutDirection, .rightToLeft)
        .presentationDetents([.height(350)])
        .onAppear {
            loadSavedBookmark()
        }
        .sheet(isPresented: $showReciterPicker) {
            ReciterPickerView(
                reciters: ReciterService.shared.availableReciters,
                selectedReciter: ReciterService.shared.selectedReciter,
                onSelect: { reciter in
                    ReciterService.shared.selectReciter(reciter)
                    if let baseURL = reciter.audioBaseURL {
                        viewModel.updateReciter(
                            baseURL: baseURL,
                            reciterName: reciter.displayName,
                            reciterId: reciter.id,
                            timingSource: reciter.timingSource
                        )
                    }
                }
            )
            .presentationDetents([.large])
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
    
    private func loadSavedBookmark() {
        let key = "mushaf_bookmark_verse_\(verse.id)"
        if UserDefaults.standard.object(forKey: key) != nil {
            activeBookmarkColorIndex = UserDefaults.standard.integer(forKey: key)
        }
    }
    
    private func saveBookmark(at index: Int) {
        let key = "mushaf_bookmark_verse_\(verse.id)"
        if activeBookmarkColorIndex == index {
            UserDefaults.standard.removeObject(forKey: key)
            activeBookmarkColorIndex = nil
        } else {
            UserDefaults.standard.set(index, forKey: key)
            activeBookmarkColorIndex = index
        }
    }
    
    
    private func playAyah() {
        var targetReciter = ReciterService.shared.selectedReciter
        if targetReciter == nil {
            targetReciter = ReciterService.shared.availableReciters.first
        }
        
        guard let reciter = targetReciter, let audioURL = reciter.audioBaseURL else { return }
        
        viewModel.configureIfNeeded(
            baseURL: audioURL,
            chapterNumber: verse.suraNo,
            chapterName: verse.suraNameAr,
            reciterName: reciter.displayName,
            reciterId: reciter.id,
            timingSource: reciter.timingSource
        )
        
        QuranPlayerCoordinator.shared.startPlayback(from: verse)
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            _ = viewModel.seekToVerse(verse.ayaNo)
        }
    }
}

#Preview {
    let mockAyah = Ayah(
        id: 1,
        ayaNo: 1,
        ayaText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
        textWithoutTashkil: "بسم الله الرحمن الرحيم",
        pageId: 1,
        suraNo: 1,
        suraNameAr: "الفاتحة",
        partId: 1,
        hizbNumber: 1,
        hizbFraction: 4,
        highlights1441: [],
        marker1441: nil
    )
    
    return AyahActionSheet(verse: mockAyah)
}
