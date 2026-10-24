//
//  MushafReadingStateManager.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation

public final class MushafReadingStateManager: Sendable {
    public static let shared = MushafReadingStateManager()
    
    private let lastPageKey = "mushaf_last_read_page"
    
    private init() {}
    
    public func saveLastPage(_ page: Int) {
        UserDefaults.standard.set(page, forKey: lastPageKey)
    }
    
    public func getLastReadPage() -> Int {
        let page = UserDefaults.standard.integer(forKey: lastPageKey)
        return page > 0 ? page : 1
    }
}
