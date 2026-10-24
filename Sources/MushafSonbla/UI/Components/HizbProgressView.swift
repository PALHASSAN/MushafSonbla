//
//  HizbProgressView.swift
//  sonbla
//
//  Created by Alhassan AlMakki on 12/12/1447 AH.
//

import SwiftUI

public struct HizbProgressView: View {
    public let hizbInfo: HizbDisplayInfo
    @AppStorage("quranTheme") private var quranTheme: String = "أبيض"
    
    public var fillColor: Color = .white
    public var outlineColor: Color {
        return self.quranTheme == "ليلي"
        ? .twNeutral500 : .twNeutral800
    }

    private var progress: CGFloat {
        CGFloat(max(0, min(hizbInfo.fraction, 1)))
    }

    private var remaining: CGFloat {
        CGFloat(max(0, min(1 - progress, 1)))
    }

    public init(hizbInfo: HizbDisplayInfo, fillColor: Color = .white, outlineColor: Color = .primary) {
        self.hizbInfo = hizbInfo
        self.fillColor = fillColor
    }

    public var body: some View {
        HStack(spacing: 6) {
            if remaining > 0 {
                ZStack {
                    Circle()
                        .fill(outlineColor)

                    HizbProgressPie(progress: remaining)
                        .fill(fillColor)
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .stroke(outlineColor, lineWidth: 1)
                }
                .frame(width: 16, height: 16)
            }
            
            Text("حزب \(hizbInfo.number.toArabic)")
                .appFont(size: 12, scalable: false)
                .foregroundStyle(quranTheme == "ليلي" ? .twNeutral200 : .twNeutral500)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("الحزب \(hizbInfo.number)")
        .accessibilityValue("التقدم \(hizbInfo.formattedFraction)")
    }
}
