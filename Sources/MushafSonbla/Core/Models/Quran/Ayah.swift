//
//  Ayah.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation
import GRDB

public struct Ayah: Identifiable, Codable, PersistableRecord, FetchableRecord, Sendable, Equatable, Hashable {
    public var id: Int
    public var ayaNo: Int
    public var ayaText: String
    public var textWithoutTashkil: String
    public var pageId: Int
    public var suraNo: Int
    public var suraNameAr: String
    public var partId: Int
    
    public var hizbNumber: Int
    public var hizbFraction: Int
    
    public var highlights1441: [VerseHighlight] = []
    public var marker1441: VerseMarker? = nil
    
    enum CodingKeys: String, CodingKey {
        case id = "verseID"
        case ayaNo = "number"
        case ayaText = "uthmanicHafsText"
        case textWithoutTashkil = "textWithoutTashkil"
        case pageId = "page_number"
        case suraNo = "sura_number"
        case partId = "part_number"
        case suraNameAr = "suraNameAr"
        case hizbNumber = "hizbNumber"
        case hizbFraction = "hizbFraction"
        case highlights1441
        case marker1441
    }
    
    public init(id: Int, ayaNo: Int, ayaText: String, textWithoutTashkil: String, pageId: Int, suraNo: Int, suraNameAr: String, partId: Int, hizbNumber: Int = 1, hizbFraction: Int = 4, highlights1441: [VerseHighlight] = [], marker1441: VerseMarker? = nil) {
        self.id = id
        self.ayaNo = ayaNo
        self.ayaText = ayaText
        self.textWithoutTashkil = textWithoutTashkil
        self.pageId = pageId
        self.suraNo = suraNo
        self.suraNameAr = suraNameAr
        self.partId = partId
        self.hizbNumber = hizbNumber
        self.hizbFraction = hizbFraction
        self.highlights1441 = highlights1441
        self.marker1441 = marker1441
    }
    
    public init(row: Row) throws {
        self.id = row["verseID"] ?? 0
        self.ayaNo = row["number"] ?? 0
        self.ayaText = row["uthmanicHafsText"] ?? ""
        self.textWithoutTashkil = row["textWithoutTashkil"] ?? ""
        self.pageId = row["page_number"] ?? 0
        self.suraNo = row["sura_number"] ?? 0
        self.suraNameAr = row["suraNameAr"] ?? ""
        self.partId = row["part_number"] ?? 0
        
        self.hizbNumber = row["hizbNumber"] ?? 1
        self.hizbFraction = row["hizbFraction"] ?? 4
        
        if let centerX: Double = row["marker1441_centerX"],
           let centerY: Double = row["marker1441_centerY"] {
            let line: Int = row["marker1441_line"] ?? row["line1441"] ?? row["line"] ?? 0
            self.marker1441 = VerseMarker(numberCodePoint: "", centerX: centerX, centerY: centerY, line: line)
        }
    }
    
    public static func == (lhs: Ayah, rhs: Ayah) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
