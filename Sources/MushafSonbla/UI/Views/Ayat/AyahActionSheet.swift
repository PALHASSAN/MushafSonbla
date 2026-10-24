//
//  AyahActionSheet.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

public struct AyahActionSheet: View {
    public let verse: Ayah
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var bookmarks: [AyahBookmark]
    @AppStorage("quranTheme") private var quranTheme: String = "أبيض"
    
    public var onPlayVerse: ((Ayah) -> Void)? = nil
    
    public var availableColors: [String] {
        if quranTheme == "ليلي" {
            return ["#059669", "#2563EB", "#D97706", "#7C3AED", "#E11D48", "#0D9488"]
        } else {
            return ["#10B981", "#3B82F6", "#F59E0B", "#8B5CF6", "#F43F5E", "#14B8A6"]
        }
    }
    
    private var activeBookmark: AyahBookmark? {
        bookmarks.first
    }
    
    public init(verse: Ayah, onPlayVerse: ((Ayah) -> Void)? = nil) {
        self.verse = verse
        self.onPlayVerse = onPlayVerse
        let verseID = verse.id
        _bookmarks = Query(filter: #Predicate<AyahBookmark> { $0.verseID == verseID })
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("سورة \(verse.suraNameAr) (\(verse.ayaNo))")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(colorScheme == .light ? Color(red: 38/255, green: 38/255, blue: 38/255) : .white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("إضافة فاصل مرجعي")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(colorScheme == .light ? Color(red: 38/255, green: 38/255, blue: 38/255) : Color(red: 229/255, green: 229/255, blue: 229/255))
                
                HStack(spacing: 16) {
                    ForEach(Array(availableColors.enumerated()), id: \.offset) { index, hex in
                        let isSelected = activeBookmark?.colorHex == "\(index)"
                        let color = Color(hex: hex)
                        
                        Button {
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                        .buttonStyle(.plain)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("التلاوة")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(colorScheme == .light ? Color(red: 38/255, green: 38/255, blue: 38/255) : Color(red: 229/255, green: 229/255, blue: 229/255))
                
                HStack(spacing: 0) {
                    Button {
                        onPlayVerse?(verse)
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Text("تشغيل الآية")
                                .font(.system(size: 15, weight: .bold))
                            
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color(red: 5/255, green: 150/255, blue: 105/255))
                        }
                        .foregroundStyle(colorScheme == .light ? Color(red: 38/255, green: 38/255, blue: 38/255) : Color(red: 229/255, green: 229/255, blue: 229/255))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorScheme == .dark ? .white.opacity(0.06) : .black.opacity(0.04))
                )
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .environment(\.layoutDirection, .rightToLeft)
        .presentationDetents([.height(300)])
    }
    
    private func saveBookmark(at index: Int) {
        let colorKey = "\(index)"
        if let existing = activeBookmark {
            if existing.colorHex == colorKey {
                modelContext.delete(existing)
            } else {
                existing.colorHex = colorKey
            }
        } else {
            let newBookmark = AyahBookmark(
                verseID: verse.id,
                suraNumber: verse.suraNo,
                ayahNumber: verse.ayaNo,
                pageNumber: verse.pageId,
                colorHex: colorKey
            )
            modelContext.insert(newBookmark)
        }
        try? modelContext.save()
    }
}

extension Color {
    init(hex: String) {
        var cleanHexCode = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanHexCode = cleanHexCode.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: cleanHexCode).scanHexInt64(&rgb)
        let redValue = Double((rgb >> 16) & 0xFF) / 255.0
        let greenValue = Double((rgb >> 8) & 0xFF) / 255.0
        let blueValue = Double(rgb & 0xFF) / 255.0
        self.init(red: redValue, green: greenValue, blue: blueValue)
    }
}
