//
//  QuranThemeHelper.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//


import SwiftUI

public enum MushafType: String, CaseIterable, Sendable {
    case text = "مصحف نصي"
    case madinah = "مصحف المدينة"
}

public struct QuranSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @AppStorage("quranTheme") private var quranTheme: String = "أبيض"
    @State private var sheetHeight: CGFloat = 320
    
    public let themes = ["أبيض", "كريمي", "ليلي"]
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("إعدادات القراءة")
                        .appFont(size: 20, weight: .bold)
                        .foregroundStyle(colorScheme == .light ? .twNeutral800 : .twNeutral200)
                    
                    Text("اختر الخلفية التي تناسبك أثناء القراءة.")
                        .appFont(size: 14)
                        .foregroundStyle(colorScheme == .light ? .twNeutral600 : .twNeutral400)
                        .multilineTextAlignment(.leading)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("لون الخلفية")
                        .appFont(size: 16, weight: .bold)
                        .foregroundStyle(colorScheme == .light ? .twNeutral800 : .twNeutral200)
                    
                    HStack(spacing: 24) {
                        ForEach(themes, id: \.self) { theme in
                            ThemeSelectionButton(
                                theme: theme,
                                isSelected: quranTheme == theme,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        quranTheme = theme
                                    }
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(30)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            sheetHeight = geo.size.height + 40
                        }
                        .onChange(of: geo.size.height) { _, newHeight in
                            sheetHeight = newHeight + 40
                        }
                }
            )
        }
        .frame(maxWidth: .infinity)
        .glowBackground()
        .environment(\.layoutDirection, .rightToLeft)
        .presentationDetents([.height(sheetHeight), .large])
        .presentationDragIndicator(.hidden)
    }
}

public struct ThemeSelectionButton: View {
    public let theme: String
    public let isSelected: Bool
    public let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(theme: String, isSelected: Bool, action: @escaping () -> Void) {
        self.theme = theme
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(QuranThemeHelper.backgroundColor(for: theme))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? .twEmerald600 : .twNeutral200.opacity(0.8), lineWidth: isSelected ? 2.5 : 1)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(theme == "ليلي" ? .white : .twEmerald600)
                            .opacity(isSelected ? 1 : 0)
                            .scaleEffect(isSelected ? 1 : 0.5)
                    )
                    .shadow(color: isSelected ? .twEmerald600.opacity(0.2) : .clear, radius: 6, y: 3)
                
                Text(theme)
                    .appFont(size: 13, weight: isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .twEmerald600 : (colorScheme == .light ? .twNeutral500 : .twNeutral200))
            }
        }
        .buttonStyle(SpatialTouchPressStyle())
    }
}

#Preview {
    QuranSettingsSheet()
}
