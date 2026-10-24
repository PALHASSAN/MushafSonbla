//
//  ItqanModels.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation

public struct ItqanPaginatedResponse<T: Decodable & Sendable>: Decodable, Sendable {
    public let count: Int?
    public let next: String?
    public let previous: String?
    public let results: [T]
}

public struct ItqanReciter: Decodable, Sendable {
    public let id: Int
    public let name: String?
}

public struct ItqanRecitationAsset: Decodable, Sendable {
    public let id: Int
    public let reciterId: Int?
    public let riwayahId: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case reciterId = "reciter_id"
        case riwayahId = "riwayah_id"
    }
}

public struct ItqanSurahTrack: Decodable, Sendable {
    public let surahNumber: Int
    public let surahName: String?
    public let audioURL: URL?
    public let durationMs: Int?
    public let ayahsCount: Int?
    public let ayahsTimings: [ItqanAyahTiming]

    enum CodingKeys: String, CodingKey {
        case surahNumber = "surah_number"
        case surahName = "surah_name"
        case audioURL = "audio_url"
        case durationMs = "duration_ms"
        case ayahsCount = "ayahs_count"
        case ayahsTimings = "ayahs_timings"
    }
}

public struct ItqanAyahTiming: Decodable, Sendable {
    public let ayahKey: String
    public let startMs: Int
    public let endMs: Int

    enum CodingKeys: String, CodingKey {
        case ayahKey = "ayah_key"
        case startMs = "start_ms"
        case endMs = "end_ms"
    }
}
