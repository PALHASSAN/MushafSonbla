//
//  Sura.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation
import GRDB

public struct Sura: Identifiable, Codable, Sendable, FetchableRecord, TableRecord {
    public static let databaseTableName = "chapters"
    
    public var id: Int { identifier }
    let identifier: Int
    let number: Int
    let isMeccan: Bool
    let title: String
    let arabicTitle: String
    
    var first_page: Int = 1
    var total_ayahs: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case identifier
        case number
        case isMeccan
        case title
        case arabicTitle
        case first_page
        case total_ayahs
    }
}

extension String {
    var cleanSuraName: String {
        return self.components(separatedBy: CharacterSet(charactersIn: "ىءآأؤإئابةتثجحخدذرزسشصضطظعغفقكلمنهويا ").inverted)
            .joined()
    }
}
