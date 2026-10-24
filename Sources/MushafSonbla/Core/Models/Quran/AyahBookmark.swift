//
//  AyahBookmark.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation
import SwiftData
import SwiftUI

@Model
public final class AyahBookmark: Identifiable, @unchecked Sendable {
    @Attribute(.unique) public var verseID: Int
    public var suraNumber: Int
    public var ayahNumber: Int
    public var pageNumber: Int
    public var dateAdded: Date
    public var colorHex: String
    
    public init(verseID: Int, suraNumber: Int, ayahNumber: Int, pageNumber: Int, colorHex: String) {
        self.verseID = verseID
        self.suraNumber = suraNumber
        self.ayahNumber = ayahNumber
        self.pageNumber = pageNumber
        self.dateAdded = Date()
        self.colorHex = colorHex
    }
}

public struct BookmarkColor: Sendable {
    public static let lightHexes = ["B8F077", "EC4899", "3B82F6", "8B5CF6", "F59E0B", "EF4444"]
    public static let darkHexes  = ["015C42", "DB2777", "2563EB", "7C3AED", "D97706", "DC2626"]
    
    public static func availableHexes(isDarkTheme: Bool) -> [String] {
        isDarkTheme ? darkHexes : lightHexes
    }
    
    public static func resolveColor(key: String, isDarkTheme: Bool) -> Color {
        if let index = Int(key) {
            let colors = availableHexes(isDarkTheme: isDarkTheme)
            if colors.indices.contains(index) {
                return Color(mushafHex: colors[index])
            }
        }
        return Color(mushafHex: key)
    }
}

// MARK: - Hex Color Helper (Internal to MushafSonbla)
private extension Color {
    init(mushafHex: String) {
        let cleanHex = mushafHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
