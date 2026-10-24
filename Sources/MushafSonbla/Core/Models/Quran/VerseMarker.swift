//
//  VerseMarker.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation

public struct VerseMarker: Codable, Hashable, Sendable {
    public var numberCodePoint: String = ""
    public var centerX: Double = 0
    public var centerY: Double = 0
    public var line: Int = 0
}
