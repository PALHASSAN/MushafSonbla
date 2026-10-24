//
//  ChapterHeader.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation

public struct ChapterHeader: Codable, Hashable, Sendable {
    public let centerX: Double
    public let centerY: Double
    public let line: Int
    
    nonisolated public init(centerX: Double, centerY: Double, line: Int) {
        self.centerX = centerX
        self.centerY = centerY
        self.line = line
    }
}
