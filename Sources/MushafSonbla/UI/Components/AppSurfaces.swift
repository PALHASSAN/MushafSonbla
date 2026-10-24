//
//  AppSurfaces.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI

enum AppSurfaces {
    static func cardBackground(
        for colorScheme: ColorScheme,
        isSelected: Bool = false,
        isEnabled: Bool = true
    ) -> Color {
        if !isEnabled {
            return colorScheme == .light
            ? .twNeutral300
            : .twNeutral800
        }
        
        if isSelected {
            return colorScheme == .light
                ? .twEmerald600.opacity(0.12)
                : .twEmerald600.opacity(0.22)
        }
        
        return colorScheme == .dark
            ? .white.opacity(0.08)
            : .white
    }
    
    static func buttonBackground(
        for colorScheme: ColorScheme,
        isEnabled: Bool = true
    ) -> Color {
        if !isEnabled {
            return colorScheme == .light
            ? .twNeutral300
            : .twNeutral800
        }
        return .twEmerald600
    }
}

private struct AppCardBackground: View {
    let radius: CGFloat
    let isCapsule: Bool
    var isSelected: Bool = false
    var isEnabled: Bool = true
    var isButton: Bool = false
    var customBackground: Color? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var resolvedFill: Color {
        if let custom = customBackground {
            return custom
        }
        if isButton {
            return AppSurfaces.buttonBackground(for: colorScheme, isEnabled: isEnabled)
        }
        return AppSurfaces.cardBackground(
            for: colorScheme,
            isSelected: isSelected,
            isEnabled: isEnabled
        )
    }
    
    var body: some View {
        Group {
            if isCapsule {
                Capsule()
                    .fill(resolvedFill)
            } else {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(resolvedFill)
            }
        }
    }
}

extension View {
    func appCard(
        radius: CGFloat = 14,
        isCapsule: Bool = false,
        isSelected: Bool = false,
        isEnabled: Bool = true,
        isButton: Bool = false,
        customBackground: Color? = nil
    ) -> some View {
        self.background(
            AppCardBackground(
                radius: radius,
                isCapsule: isCapsule,
                isSelected: isSelected,
                isEnabled: isEnabled,
                isButton: isButton,
                customBackground: customBackground
            )
        )
    }
}

#Preview("AppCard Showcase") {
    AppCardPreviewDemo()
}

private struct AppCardPreviewDemo: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedIndex: Int = 1
    @State private var isButtonEnabled: Bool = false
    @State private var customColorActive: Bool = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("حالات الاختيار (Default & Selected)")
                        .font(.appFont(size: 13, weight: .bold))
                        .foregroundStyle(colorScheme == .light ? .twNeutral500 : .twNeutral400)
                    
                    VStack(spacing: 8) {
                        previewOptionRow(
                            id: 0,
                            title: "أسبوع",
                            subtitle: "87 صفحة / يوم",
                            badge: "مكثف"
                        )
                        
                        previewOptionRow(
                            id: 1,
                            title: "أسبوعين",
                            subtitle: "44 صفحة / يوم",
                            badge: "متوسط"
                        )
                        
                        previewOptionRow(
                            id: 2,
                            title: "شهر",
                            subtitle: "21 صفحة / يوم",
                            badge: "يومي"
                        )
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("الكبسولات (isCapsule: true)")
                        .font(.appFont(size: 13, weight: .bold))
                        .foregroundStyle(colorScheme == .light ? .twNeutral500 : .twNeutral400)
                    
                    HStack(spacing: 8) {
                        Text("ختمة عامة")
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundStyle(.twEmerald600)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .appCard(isCapsule: true, isSelected: true)
                        
                        Text("ختمة رمضان")
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundStyle(colorScheme == .light ? .twNeutral700 : .twNeutral300)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .appCard(isCapsule: true, isSelected: false)
                        
                        Text("معطلة")
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundStyle(.twNeutral400)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .appCard(isCapsule: true, isEnabled: false)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("الأزرار العائمة والتخصيص")
                            .font(.appFont(size: 13, weight: .bold))
                            .foregroundStyle(colorScheme == .light ? .twNeutral500 : .twNeutral400)
                        
                        Spacer()
                        
                        Toggle("", isOn: $isButtonEnabled)
                            .labelsHidden()
                    }
                    
                    Button {
                        
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            
                            Text("إنشاء ختمة جديدة")
                                .font(.appFont(size: 15, weight: .bold))
                        }
                        .foregroundStyle(isButtonEnabled ? .white : .twNeutral400)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .appCard(
                            isCapsule: true,
                            isEnabled: isButtonEnabled,
                            customBackground: isButtonEnabled ? .twEmerald600 : nil
                        )
                    }
                    .disabled(!isButtonEnabled)
                    .buttonStyle(SpatialTouchPressStyle())
                    
                    HStack(spacing: 12) {
                        Image(systemName: isButtonEnabled ? "lock.open.fill" : "lock.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(isButtonEnabled ? .twEmerald600 : .twNeutral400)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(isButtonEnabled ? "البطاقة مفعلة" : "البطاقة معطلة (Disabled)")
                                .font(.appFont(weight: .bold))
                                .foregroundStyle(isButtonEnabled ? (colorScheme == .light ? .twNeutral900 : .white) : .twNeutral400)
                            
                            Text("اختبار تدرج الشفافية عند تبديل isEnabled")
                                .font(.appFont(size: 11))
                                .foregroundStyle(.twNeutral400)
                        }
                        
                        Spacer()
                    }
                    .padding(14)
                    .appCard(radius: 14, isEnabled: isButtonEnabled)
                }
            }
            .padding()
        }
        .glowBackground()
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    private func previewOptionRow(id: Int, title: String, subtitle: String, badge: String) -> some View {
        let isSelected = selectedIndex == id
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedIndex = id
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.appFont(size: 15, weight: .bold))
                            .foregroundStyle(colorScheme == .light ? .twNeutral800 : .white)
                        
                        SectionBadge(title: badge, fontSize: 10)
                    }
                    
                    Text(subtitle)
                        .font(.appFont(size: 12))
                        .foregroundStyle(colorScheme == .light ? .twNeutral500 : .twNeutral400)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.twEmerald600)
                }
            }
            .padding(14)
            .appCard(radius: 16, isSelected: isSelected)
        }
        .buttonStyle(SpatialTouchPressStyle())
    }
}
