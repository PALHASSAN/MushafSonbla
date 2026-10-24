//
//  MushafSession.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation

public enum SessionType: Equatable, Sendable {
    case freeReading
    case khatma(targetPage: Int, dailyQuota: Int)
    case revision(range: ClosedRange<Int>)
}

public struct MushafSession: Sendable {
    public let id: String
    public let title: String?
    public let startPage: Int
    public let targetPage: Int?
    public let range: ClosedRange<Int>?
    
    public var type: SessionType {
        if let range = range {
            return .revision(range: range)
        } else if let target = targetPage, target > startPage {
            let quota = target - startPage + 1
            return .khatma(targetPage: target, dailyQuota: quota)
        } else {
            return .freeReading
        }
    }
    
    public static func free(page: Int = 1) -> MushafSession {
        MushafSession(id: UUID().uuidString, title: nil, startPage: page, targetPage: nil, range: nil)
    }
    
    public static func khatma(id: String = UUID().uuidString, title: String = "ختمة", startPage: Int, targetEndPage: Int) -> MushafSession {
        MushafSession(id: id, title: title, startPage: startPage, targetPage: targetEndPage, range: nil)
    }
    
    public static func revision(range: ClosedRange<Int>, title: String = "مراجعة") -> MushafSession {
        MushafSession(id: UUID().uuidString, title: title, startPage: range.lowerBound, targetPage: nil, range: range)
    }
    
    private init(id: String, title: String?, startPage: Int, targetPage: Int?, range: ClosedRange<Int>?) {
        self.id = id
        self.title = title
        self.startPage = startPage
        self.targetPage = targetPage
        self.range = range
    }
}
