//
//  SectionBadge.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI

struct SectionBadge: View {
    var title: String? = nil
    var fontSize: CGFloat = 13
    var textColor: Color = .twEmerald600
    var systemIcon: String? = nil
    var isScalable: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var iconSize: CGFloat { fontSize * 0.85 }
    private var spacing: CGFloat { fontSize * 0.45 }
    private var horizontalPadding: CGFloat { fontSize * 0.9 }
    private var verticalPadding: CGFloat { fontSize * 0.45 }
    
    private var circleSize: CGFloat { fontSize * 1.9 }
    
    var body: some View {
        HStack(spacing: spacing) {
            if let icon = systemIcon {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .semibold))
            }
            
            if let titleText = title {
                Text(titleText)
                    .appFont(size: fontSize, weight: .bold, scalable: isScalable)
            }
        }
        .foregroundStyle(textColor)
        .lineLimit(1)
        .fixedSize()
        .frame(width: title == nil ? circleSize : nil, height: title == nil ? circleSize : nil)
        .padding(.horizontal, title == nil ? 0 : horizontalPadding)
        .padding(.vertical, title == nil ? 0 : verticalPadding)
        .background {
            if title == nil {
                Circle()
                    .fill(textColor.opacity(colorScheme == .dark ? 0.16 : 0.08))
            } else {
                Capsule()
                    .fill(textColor.opacity(colorScheme == .dark ? 0.16 : 0.08))
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SectionBadge(title: "الاستئذان", systemIcon: "door.left.hand.open")
        SectionBadge(title: "نص الزيارة الشريفة")
    }
}
