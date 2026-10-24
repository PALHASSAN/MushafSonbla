//
//  VerseFasel.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI

public struct VerseFasel: View {
    public let number: Int
    public var scale: CGFloat = 1.0
    private let balance: CGFloat = 3.69
    @AppStorage("quranTheme") private var quranTheme: String = "أبيض"
    
    public init(number: Int, scale: CGFloat = 1.0) {
        self.number = number
        self.scale = scale
    }
    
    public var body: some View {
        let baseWidth: CGFloat = 21 * balance
        let baseHeight: CGFloat = 27 * balance
        let baseFontSize: CGFloat = 24 * balance
        let basePadding: CGFloat = 2 * balance
        let fontSize = baseFontSize * scale
        
        Image(quranTheme == "ليلي" ? "Sura/ayahNumberDark" : "Sura/ayahNumber")
            .resizable()
            .frame(width: baseWidth * scale, height: baseHeight * scale, alignment: .center)
            .overlay {
                Text(number.toArabic)
                    .font(.hafsSmart(size: fontSize))
                    .foregroundColor(.twNeutral800)
                    .minimumScaleFactor(0)
                    .padding(.horizontal, basePadding * scale)
                    .offset(x: 1 * scale, y: -11 * scale)
            }
            .offset(x: -0.5, y: 0)
    }
}

public extension Int {
    var toArabic: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

public extension Image {
    init(_ name: String) {
        self.init(name, bundle: .module)
    }
}

#Preview {
    VerseFasel(number: 286)
}
