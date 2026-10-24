//
//  ReciterTiming.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation

public struct ReciterTiming: Codable, Sendable {
    public let id: Int
    public let name: String
    public let name_en: String
    public let rewaya: String
    public let folder_url: String
    public let chapters: [ChapterTiming]

    public init(id: Int, name: String, name_en: String, rewaya: String, folder_url: String, chapters: [ChapterTiming]) {
        self.id = id
        self.name = name
        self.name_en = name_en
        self.rewaya = rewaya
        self.folder_url = folder_url
        self.chapters = chapters
    }
}

public struct ChapterTiming: Codable, Sendable {
    public let id: Int
    public let name: String
    public let aya_timing: [AyahTiming]

    public init(id: Int, name: String, aya_timing: [AyahTiming]) {
        self.id = id
        self.name = name
        self.aya_timing = aya_timing
    }
}

public struct AyahTiming: Codable, Sendable {
    public let ayah: Int
    public let start_time: Int
    public let end_time: Int

    public init(ayah: Int, start_time: Int, end_time: Int) {
        self.ayah = ayah
        self.start_time = start_time
        self.end_time = end_time
    }
}
