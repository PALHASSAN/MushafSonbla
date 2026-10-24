//
//  Page.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation
import GRDB

public struct Page: Identifiable, Hashable, Equatable {
    public let id: Int
    public let number: Int
    public let isRight: Bool
    public let verses1441: [Ayah]
    public let chapterHeaders1441: [ChapterHeader]
    
    public init(identifier: Int, number: Int, isRight: Bool, verses: [Ayah], headers: [ChapterHeader]) {
        self.id = identifier
        self.number = number
        self.isRight = isRight
        self.verses1441 = verses
        self.chapterHeaders1441 = headers
    }
    
    public static func == (lhs: Page, rhs: Page) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
