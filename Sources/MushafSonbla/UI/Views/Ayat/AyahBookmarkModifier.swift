//
//  AyahBookmarkModifier.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI
import SwiftData

struct AyahBookmarkModifier: ViewModifier {
    let verseID: Int
    let suraNumber: Int
    let ayahNumber: Int
    
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [AyahBookmark]
    @AppStorage("quranTheme") private var quranTheme: String = "أبيض"
    
    init(verseID: Int, suraNumber: Int, ayahNumber: Int) {
        self.verseID = verseID
        self.suraNumber = suraNumber
        self.ayahNumber = ayahNumber
        
        let predicate = #Predicate<AyahBookmark> { $0.verseID == verseID }
        _bookmarks = Query(filter: predicate)
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if let bookmark = bookmarks.first {
                        BookmarkColor.resolveColor(key: bookmark.colorHex, isDarkTheme: quranTheme == "ليلي")
                    } else {
                        Color.clear
                    }
                }
            )
            .animation(.easeInOut(duration: 0.2), value: bookmarks.first?.colorHex)
            .simultaneousGesture(
                TapGesture(count: 2).onEnded {
                    removeBookmark()
                }
            )
    }
    
    private func removeBookmark() {
        if let existing = bookmarks.first {
            withAnimation {
                modelContext.delete(existing)
            }
        }
    }
}

extension View {
    func supportDoubleTapBookmark(verseID: Int, suraNumber: Int, ayahNumber: Int) -> some View {
        self.modifier(AyahBookmarkModifier(verseID: verseID, suraNumber: suraNumber, ayahNumber: ayahNumber))
    }
}
