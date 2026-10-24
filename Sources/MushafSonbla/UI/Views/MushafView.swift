//
//  MushafView.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI

public struct MushafView: View {
    private let pageId: Int?
    private let suraNo: Int?
    private let targetPageId: Int?
    private let khatmaId: String?
    private let targetAyaNo: Int?
    private let onPageRead: ((Int) -> Void)?
    private let onTargetReached: ((Int) -> Void)?
    
    public init(
        pageId: Int? = 1,
        suraNo: Int? = nil,
        targetPageId: Int? = nil,
        khatmaId: String? = nil,
        targetAyaNo: Int? = nil,
        onPageRead: ((Int) -> Void)? = nil,
        onTargetReached: ((Int) -> Void)? = nil
    ) {
        self.pageId = pageId
        self.suraNo = suraNo
        self.targetPageId = targetPageId
        self.khatmaId = khatmaId
        self.targetAyaNo = targetAyaNo
        self.onPageRead = onPageRead
        self.onTargetReached = onTargetReached
    }
    
    public var body: some View {
        QuranShow(
            suraNo: suraNo,
            pageId: pageId,
            targetAyaNo: targetAyaNo,
            khatmaId: khatmaId,
            targetPageId: targetPageId,
            onPageRead: onPageRead,
            onTargetReached: onTargetReached
        )
    }
}

#Preview("Quran") {
    MushafView(pageId: 1)
}

#Preview("Khatma") {
    MushafView(
        pageId: 2,
        targetPageId: 3,
        khatmaId: "khatma_ramadan",
        onTargetReached: { page in
            print("تم إتمام ورد اليوم عند صفحة: \(page)")
        }
    )
}
