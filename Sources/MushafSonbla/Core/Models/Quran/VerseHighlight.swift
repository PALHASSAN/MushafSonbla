//
//  VerseHighlight.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation
import GRDB

public struct VerseHighlight: Codable, Hashable, Sendable, FetchableRecord {
    public var id: Int
    public var verseId: Int
    public var layoutType: Int
    public var line: Int
    public var left: Double
    public var right: Double
    
    public enum CodingKeys: String, CodingKey {
        case id
        case verseId = "verse_id"
        case layoutType = "layout_type"
        case line
        case left = "left_position"
        case right = "right_position"
    }
}
