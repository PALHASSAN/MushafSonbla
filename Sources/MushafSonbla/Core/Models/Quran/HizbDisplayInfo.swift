//
//  HizbDisplayInfo.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation

public struct HizbDisplayInfo: Sendable {
    public let number: Int
    public let fraction: Double

    nonisolated public init(number: Int, hizbFraction: Int) {
        self.number = number
        self.fraction = HizbDisplayInfo.fractionValue(for: hizbFraction)
    }

    public var formattedFraction: String {
        String(format: "%.2f", fraction)
    }

    nonisolated private static func fractionValue(for hizbFraction: Int) -> Double {
        switch hizbFraction {
        case 1:
            return 0.25
        case 2:
            return 0.5
        case 3:
            return 0.75
        default:
            return 1.0
        }
    }
}
