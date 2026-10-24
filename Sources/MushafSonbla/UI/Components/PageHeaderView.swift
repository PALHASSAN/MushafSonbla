//
//  PageHeaderView.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI

struct PageHeaderView: View {
    public let page: Page
    public var horizontalPadding: CGFloat = 16
    @AppStorage("quranTheme") private var quranTheme: String = "أبيض"
    
    private var hizbInfo: HizbDisplayInfo?
    
    public init(page: Page, hizbInfo: HizbDisplayInfo? = nil, horizontalPadding: CGFloat = 16) {
        self.page = page
        self.hizbInfo = hizbInfo
        self.horizontalPadding = horizontalPadding
    }
    
    public var body: some View {
        HStack {
            let surahs = uniqueSurahs(from: page.verses1441)
            
            HStack(spacing: 8) {
                ForEach(surahs, id: \.self) { title in
                    Text(title)
                        .font(.sura(size: 20))
                        .foregroundStyle(quranTheme == "ليلي" ? .white : .primary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if let displayPart = resolvedPartNumber(from: page.verses1441) {
                    Text("الجزء \(displayPart.toArabic)")
                        .appFont(size: 12, scalable: false)
                        .foregroundStyle(quranTheme == "ليلي" ? .secondary : .secondary)
                }
                
                if let info = hizbInfo {
                    HizbProgressView(hizbInfo: info)
                }
            }
            
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .environment(\.layoutDirection, .rightToLeft)
    }
    
   
    private func resolvedPartNumber(from verses: [Ayah]) -> Int? {
        guard !verses.isEmpty else { return nil }
        
        let rawPartId = verses.map(\.partId).max() ?? verses.first!.partId
        return rawPartId == 0 ? 1 : rawPartId
    }
    
    private func uniqueSurahs(from verses: [Ayah]) -> [String] {
        let newSurahs = verses.filter { $0.ayaNo == 1 }.map { $0.suraNameAr }
        
        if !newSurahs.isEmpty {
            return newSurahs
        }
        
        if let first = verses.first?.suraNameAr {
            return [first]
        }
        
        return []
    }
}

#Preview("PageHeaderView - نهاري") {
    let sampleVerses = [
        Ayah(
            id: 1,
            ayaNo: 1,
            ayaText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            textWithoutTashkil: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            pageId: 1,
            suraNo: 1,
            suraNameAr: "الفاتحة",
            partId: 1
        )
    ]
    
    let mockPage = Page(
        identifier: 1,
        number: 1,
        isRight: false,
        verses: sampleVerses, headers: []
    )
    
    let mockHizb = HizbDisplayInfo(number: 1, hizbFraction: 2)
    
    PageHeaderView(
        page: mockPage,
        hizbInfo: mockHizb,
        horizontalPadding: 16
    )
    .background(Color.white)
}

#Preview("PageHeaderView - ليلي") {
    let sampleVerses = [
        Ayah(
            id: 1,
            ayaNo: 1,
            ayaText: "الم",
            textWithoutTashkil: "الم",
            pageId: 1,
            suraNo: 2,
            suraNameAr: "البقرة",
            partId: 1
        )
    ]
    
    
    let mockPage = Page(
        identifier: 2,
        number: 2,
        isRight: false,
        verses: sampleVerses, headers: []
    )
    
    let mockHizb = HizbDisplayInfo(number: 1, hizbFraction: 3)
    
    PageHeaderView(
        page: mockPage,
        hizbInfo: mockHizb,
        horizontalPadding: 16
    )
    .background(.black)
    .environment(\.colorScheme, .dark)
}
