//
//  PageFooterView.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI

struct PageFooterView: View, Equatable {
    public let pageNumber: Int
    public let isRight: Bool
    
    @AppStorage("quranTheme") private var quranTheme: String = "أبيض"
    
    @State private var isLandscape: Bool = {
        #if canImport(UIKit)
        let bounds = UIScreen.main.bounds
        return bounds.width > bounds.height
        #else
        return false
        #endif
    }()
    
    private var scaleFactor: CGFloat { isLandscape ? 2.0 : 1.0 }
    private var baseWidth: CGFloat { 42 * scaleFactor }
    private var baseHeight: CGFloat { 26 * scaleFactor }
    private var baseFont: CGFloat { 35 * scaleFactor }
    private var fontOffset: CGFloat { isLandscape ? -11.5 : -4.5 }
    
    public init(pageNumber: Int, isRight: Bool) {
        self.pageNumber = pageNumber
        self.isRight = isRight
    }
    
    static func == (lhs: PageFooterView, rhs: PageFooterView) -> Bool {
        lhs.pageNumber == rhs.pageNumber &&
        lhs.isRight == rhs.isRight &&
        lhs.quranTheme == rhs.quranTheme
    }
    
    public var body: some View {
        HStack {
            if isRight {
                footerContent
                Spacer()
            } else {
                Spacer()
                footerContent
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            #if canImport(UIKit)
            let bounds = UIScreen.main.bounds
            isLandscape = bounds.width > bounds.height
            #endif
        }
    }
    
    private var footerContent: some View {
        ZStack {
            Image(quranTheme == "ليلي" ? "Sura/pageNumberDark" : "Sura/pageNumber")
                .resizable()
                .frame(width: baseWidth, height: baseHeight)
            
            Text(pageNumber.toArabic)
                .font(.hafsSmart(size: baseFont))
                .foregroundColor(.twNeutral800)
                .offset(y: fontOffset)
        }
        .drawingGroup()
    }
}

#Preview {
    PageFooterView(pageNumber: 604, isRight: true)
}
