//
//  QuranDB.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation
import GRDB

public struct QuranDB: Sendable {
    public static let shared = QuranDB()
    private let dbQueue: DatabaseQueue
    
    private init() {
        guard let databasePath = Bundle.module.path(forResource: "quran", ofType: "sqlite") else {
            fatalError("Could not find 'quran.sqlite' in MushafSonbla Bundle.module.")
        }
        
        do {
            var configuration = Configuration()
            configuration.readonly = true
            configuration.prepareDatabase { database in
                try database.execute(sql: "PRAGMA cache_size = 500")
            }
            
            self.dbQueue = try DatabaseQueue(path: databasePath, configuration: configuration)
#if DEBUG
            print("Database Connected successfully at: \(databasePath) ✅")
#endif
        } catch {
            fatalError("Connection failed ❌ \(error)")
        }
    }
    
    public func getAyahsByPage(pageId: Int) async throws -> [Ayah] {
        return try await dbQueue.read { database in
            let sql = """
                SELECT v.verseID, v.number, v.uthmanicHafsText AS uthmanicHafsText, 
                (v.page1441_id + 1) AS page_number, 
                c.number AS sura_number, 
                pt.number AS part_number, 
                c.arabicTitle AS suraNameAr,
                v.marker1441_centerX, 
                v.marker1441_centerY,
                v.marker1441_line,
                q.hizbNumber, 
                q.hizbFraction
                FROM verses v
                JOIN chapters c ON v.chapter_id = c.identifier
                JOIN pages pg ON v.page1441_id = pg.identifier
                JOIN parts pt ON v.part_id = pt.identifier
                JOIN quarters q ON v.quarter_id = q.identifier
                WHERE pg.number = ? 
                ORDER BY c.number ASC, v.number ASC
                """
            
            let databaseRows = try Row.fetchAll(database, sql: sql, arguments: [pageId])
            var retrievedAyahs: [Ayah] = []
            
            for row in databaseRows {
                var ayah = try Ayah(row: row)
                let highlightSql = "SELECT * FROM verse_highlights WHERE verse_id = ? AND layout_type = 1441"
                let highlights = try VerseHighlight.fetchAll(database, sql: highlightSql, arguments: [ayah.id])
                
                ayah.highlights1441 = highlights
                retrievedAyahs.append(ayah)
            }
            return retrievedAyahs
        }
    }
    
    public func getHizbInfoForPage(pageId: Int) async throws -> HizbDisplayInfo? {
        return try await dbQueue.read { database in
            let sql = """
                SELECT q.hizbNumber, q.hizbFraction 
                FROM pages pg
                JOIN quarters q ON pg.header1441_quarter_id = q.identifier
                WHERE pg.number = ?
                LIMIT 1
                """
            
            if let row = try Row.fetchOne(database, sql: sql, arguments: [pageId]) {
                let hizbNumber: Int = row["hizbNumber"]
                let hizbFraction: Int = row["hizbFraction"]
                return HizbDisplayInfo(number: hizbNumber, hizbFraction: hizbFraction)
            }
            return nil
        }
    }
    
    public func getHighlights(forVerse verseId: Int64) async throws -> [VerseHighlight] {
        return try await dbQueue.read { database in
            let sql = "SELECT * FROM verse_highlights WHERE verse_id = ? AND layout_type = 1441"
            return try VerseHighlight.fetchAll(database, sql: sql, arguments: [verseId])
        }
    }
    
    public func getAllSuras() async throws -> [Sura] {
        return try await dbQueue.read { database in
            let sql = """
                SELECT c.identifier, c.number, c.isMeccan, c.title, c.arabicTitle, 
                (MIN(v.page1441_id) + 1) AS first_page, 
                COUNT(v.verseID) AS total_ayahs
                FROM chapters c
                JOIN verses v ON (v.chapter_id + 1) = c.number
                GROUP BY c.number
                ORDER BY c.number ASC
                """
            return try Sura.fetchAll(database, sql: sql)
        }
    }
    
    public func getStartPageForSura(_ suraNumber: Int) async throws -> Int {
        return try await dbQueue.read { database in
            let sql = "SELECT (MIN(page1441_id) + 1) FROM verses WHERE (chapter_id + 1) = ?"
            return try Int.fetchOne(database, sql: sql, arguments: [suraNumber]) ?? 1
        }
    }
    
    public func getPagesForSura(_ suraNumber: Int) async throws -> [Int] {
        return try await dbQueue.read { database in
            let sql = "SELECT DISTINCT (page1441_id + 1) FROM verses WHERE (chapter_id + 1) = ? ORDER BY page1441_id ASC"
            return try Int.fetchAll(database, sql: sql, arguments: [suraNumber])
        }
    }
    
    public func getChapterHeadersByPage(pageId: Int) async throws -> [ChapterHeader] {
        return try await dbQueue.read { database in
            let sql = """
                SELECT line, centerX, centerY 
                FROM chapter_headers 
                WHERE page_id = ? AND layout_type = 1441
                GROUP BY line
                """
            let rows = try Row.fetchAll(database, sql: sql, arguments: [pageId - 1])
            var chapterHeaders: [ChapterHeader] = []
            
            for row in rows {
                let lineNumber: Int = row["line"]
                let rawCenterX: Double = row["centerX"]
                let rawCenterY: Double = row["centerY"]
                
                let normalizedX = rawCenterX > 1.5 ? (rawCenterX / 1440.0) : rawCenterX
                let normalizedY = rawCenterY > 1.5 ? (rawCenterY / 232.0) : rawCenterY
                
                chapterHeaders.append(ChapterHeader(centerX: normalizedX, centerY: normalizedY, line: lineNumber))
            }
            return chapterHeaders
        }
    }
    
    public func getAyahsForPageAndSura(pageId: Int, suraNumber: Int) async throws -> [Ayah] {
        return try await dbQueue.read { database in
            let sql = """
                SELECT v.verseID, v.number, v.uthmanicHafsText AS uthmanicHafsText,
                (v.page1441_id + 1) AS page_number, 
                c.number AS sura_number, 
                pt.number AS part_number, 
                c.arabicTitle AS suraNameAr,
                v.marker1441_centerX, 
                v.marker1441_centerY
                FROM verses v
                JOIN chapters c ON (v.chapter_id + 1) = c.number
                JOIN parts pt ON v.part_id = pt.identifier
                WHERE (v.page1441_id + 1) = ? AND c.number = ? 
                ORDER BY v.number ASC
                """
            return try Ayah.fetchAll(database, sql: sql, arguments: [pageId, suraNumber])
        }
    }
    
    public func getSuraNumber(forPage pageId: Int) async throws -> Int? {
        return try await dbQueue.read { database in
            let sql = "SELECT (chapter_id + 1) FROM verses WHERE (page1441_id + 1) = ? LIMIT 1"
            return try Int.fetchOne(database, sql: sql, arguments: [pageId])
        }
    }
    
    public func getAllAyahs() async throws -> [Ayah] {
        return try await dbQueue.read { database in
            let sql = """
                SELECT v.verseID, v.number, v.uthmanicHafsText AS uthmanicHafsText, 
                (v.page1441_id + 1) AS page_number, 
                c.number AS sura_number, 
                pt.number AS part_number, 
                c.arabicTitle AS suraNameAr,
                v.marker1441_centerX, 
                v.marker1441_centerY
                FROM verses v
                JOIN chapters c ON (v.chapter_id + 1) = c.number
                JOIN parts pt ON v.part_id = pt.identifier
                ORDER BY c.number ASC, v.number ASC
                """
            return try Ayah.fetchAll(database, sql: sql)
        }
    }
    
    public func getSura(id: Int) async throws -> Sura? {
        return try await dbQueue.read { database in
            let sql = """
                SELECT c.identifier, c.number, c.isMeccan, c.title, c.arabicTitle, 
                (MIN(v.page1441_id) + 1) AS first_page, 
                COUNT(v.verseID) AS total_ayahs
                FROM chapters c
                JOIN verses v ON (v.chapter_id + 1) = c.number
                WHERE c.number = ?
                GROUP BY c.number
                LIMIT 1
                """
            return try Sura.fetchOne(database, sql: sql, arguments: [id])
        }
    }
    
    public func getPageForVerse(suraNo: Int, ayaNo: Int) async throws -> Int? {
        return try await dbQueue.read { database in
            let sql = "SELECT (page1441_id + 1) FROM verses WHERE (chapter_id + 1) = ? AND number = ? LIMIT 1"
            return try Int.fetchOne(database, sql: sql, arguments: [suraNo, ayaNo])
        }
    }
    
    public func getRandomShortAyah(maxCharacters: Int = 50) async throws -> Ayah? {
        return try await dbQueue.read { database in
            let sql = """
                SELECT v.verseID, v.number, v.uthmanicHafsText AS uthmanicHafsText, 
                pg.number AS page_number, 
                c.number AS sura_number, 
                pt.number AS part_number, 
                c.arabicTitle AS suraNameAr,
                v.marker1441_centerX, 
                v.marker1441_centerY
                FROM verses v
                JOIN chapters c ON v.chapter_id = c.identifier
                JOIN pages pg ON v.page1441_id = pg.identifier
                JOIN parts pt ON v.part_id = pt.identifier
                WHERE LENGTH(v.text) <= ? 
                ORDER BY RANDOM() LIMIT 1
                """
            return try Ayah.fetchOne(database, sql: sql, arguments: [maxCharacters])
        }
    }
}

public struct QuranPartWithSuras: Identifiable, Sendable {
    public var id: Int { partNumber }
    public let partNumber: Int
    public let startPage: Int
    public let suras: [Sura]
    
    public init(partNumber: Int, startPage: Int, suras: [Sura]) {
        self.partNumber = partNumber
        self.startPage = startPage
        self.suras = suras
    }
}

public struct QuranHizbWithSuras: Identifiable, Sendable {
    public var id: Int { hizbNumber }
    public let hizbNumber: Int
    public let startPage: Int
    public let suras: [Sura]
    
    public init(hizbNumber: Int, startPage: Int, suras: [Sura]) {
        self.hizbNumber = hizbNumber
        self.startPage = startPage
        self.suras = suras
    }
}

public extension QuranDB {
    func getAllPartsWithSuras() async throws -> [QuranPartWithSuras] {
        return try await dbQueue.read { database in
            let sql = """
                SELECT 
                    (v.part_id + 1) AS part_number,
                    c.identifier, 
                    c.number, 
                    c.isMeccan, 
                    c.title, 
                    c.arabicTitle, 
                    (MIN(v.page1441_id) + 1) AS first_page, 
                    COUNT(v.verseID) AS total_ayahs
                FROM verses v
                JOIN chapters c ON (v.chapter_id + 1) = c.number
                GROUP BY v.part_id, c.number
                ORDER BY v.part_id ASC, c.number ASC
                """
            
            let rows = try Row.fetchAll(database, sql: sql)
            var partsDictionary: [Int: [Sura]] = [:]
            var partStartPages: [Int: Int] = [:]
            
            for row in rows {
                let partNumber: Int = row["part_number"]
                let pageNumber: Int = row["first_page"]
                let sura = try Sura(row: row)
                
                partsDictionary[partNumber, default: []].append(sura)
                if partStartPages[partNumber] == nil {
                    partStartPages[partNumber] = pageNumber
                }
            }
            
            return (1...30).compactMap { partNumber in
                guard let surasInPart = partsDictionary[partNumber] else { return nil }
                return QuranPartWithSuras(
                    partNumber: partNumber,
                    startPage: partStartPages[partNumber] ?? 1,
                    suras: surasInPart
                )
            }
        }
    }
    
    func getAllHizbsWithSuras() async throws -> [QuranHizbWithSuras] {
        return try await dbQueue.read { database in
            let pageSql = """
                SELECT 
                    q.hizbNumber, 
                    (MIN(v.page1441_id) + 1) AS start_page
                FROM verses v
                JOIN quarters q ON v.quarter_id = q.identifier
                GROUP BY q.hizbNumber
                ORDER BY q.hizbNumber ASC
                """
            let pageRows = try Row.fetchAll(database, sql: pageSql)
            var hizbStartPages: [Int: Int] = [:]
            for row in pageRows {
                let hizbNumber: Int = row["hizbNumber"]
                let startPage: Int = row["start_page"]
                hizbStartPages[hizbNumber] = startPage
            }
            
            let surasSql = """
                SELECT 
                    q.hizbNumber, 
                    c.identifier, 
                    c.number, 
                    c.isMeccan, 
                    c.title, 
                    c.arabicTitle, 
                    (MIN(v.page1441_id) + 1) AS first_page, 
                    COUNT(v.verseID) AS total_ayahs
                FROM verses v
                JOIN quarters q ON v.quarter_id = q.identifier
                JOIN chapters c ON (v.chapter_id + 1) = c.number
                GROUP BY q.hizbNumber, c.number
                ORDER BY q.hizbNumber ASC, c.number ASC
                """
            let suraRows = try Row.fetchAll(database, sql: surasSql)
            var hizbSurasDictionary: [Int: [Sura]] = [:]
            for row in suraRows {
                let hizbNumber: Int = row["hizbNumber"]
                let sura = try Sura(row: row)
                hizbSurasDictionary[hizbNumber, default: []].append(sura)
            }
            
            return (1...60).compactMap { hizbNumber in
                guard let suras = hizbSurasDictionary[hizbNumber] else { return nil }
                return QuranHizbWithSuras(
                    hizbNumber: hizbNumber,
                    startPage: hizbStartPages[hizbNumber] ?? 1,
                    suras: suras
                )
            }
        }
    }
}
