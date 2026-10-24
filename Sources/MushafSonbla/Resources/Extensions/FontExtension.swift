//
//  FontExtension.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI
import CoreText

public enum MushafFontLoader {
    nonisolated(unsafe) private static var isRegistered = false

    public static func registerFonts() {
        guard !isRegistered else { return }
        
        let extensions = ["ttf", "otf"]
        
        for ext in extensions {
            if let urls = Bundle.module.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                for url in urls {
                    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                }
            }
            
            if let urls = Bundle.module.urls(forResourcesWithExtension: ext, subdirectory: "Fonts") {
                for url in urls {
                    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                }
            }
        }
        
        isRegistered = true
    }
}

public enum FontType: String {
    case alexandira
    case sura
    case quran
}

private struct AppFontTypeKey: EnvironmentKey {
    static let defaultValue: String = FontType.alexandira.rawValue
}

public extension EnvironmentValues {
    var appFontType: String {
        get { self[AppFontTypeKey.self] }
        set { self[AppFontTypeKey.self] = newValue }
    }
}

public extension Font {
    static func alexandira(size: CGFloat = 14, weight: Font.Weight = .regular) -> Font {
        MushafFontLoader.registerFonts()
        
        let name: String
        switch weight {
        case .black:
            name = "Alexandria-Regular_Black"
        case .bold:
            name = "Alexandria-Regular_Bold"
        case .medium:
            name = "Alexandria-Regular_Medium"
        case .semibold:
            name = "Alexandria-Regular_SemiBold"
        case .thin:
            name = "Alexandria-Regular_Thin"
        case .light:
            name = "Alexandria-Regular_Light"
        case .ultraLight:
            name = "Alexandria-Regular_ExtraLight"
        default:
            name = "Alexandria-Regular"
        }
        
        return .custom(name, size: size)
    }
    
    static func quran(size: CGFloat = 24, weight: Font.Weight = .regular) -> Font {
        MushafFontLoader.registerFonts()
        let name = "kfgqpchafsuthmanicscript-Reg"
        return .custom(name, size: size)
    }
    
    static func sura(size: CGFloat = 22, weight: Font.Weight = .regular) -> Font {
        MushafFontLoader.registerFonts()
        let name = "Elgharib-QCF4SurahNames"
        return .custom(name, size: size)
    }
    
    static func hafsSmart(size: CGFloat = 14, weight: Font.Weight = .regular) -> Font {
        MushafFontLoader.registerFonts()
        let name = "KFGQPCHafsSmart-Regular"
        return .custom(name, size: size)
    }
    
    static func appFont(
        size: CGFloat = 14,
        weight: Font.Weight = .regular,
        fontType: FontType? = nil,
        scalable: Bool = true,
        customLevel: Double? = nil,
        overrideFontRaw: String? = nil
    ) -> Font {
        MushafFontLoader.registerFonts()
        
        let savedFontRaw = overrideFontRaw ?? UserDefaults.standard.string(forKey: "appFontType") ?? FontType.alexandira.rawValue
        let selectedFont = fontType ?? FontType(rawValue: savedFontRaw) ?? .alexandira
        
        let level = scalable ? (customLevel ?? UserDefaults.standard.double(forKey: "appFontSize")) : 0.0
        let finalSize = size + level
        
        switch selectedFont {
        case .sura:
            return sura(size: finalSize, weight: weight)
        case .quran:
            return quran(size: finalSize, weight: weight)
        case .alexandira:
            return alexandira(size: finalSize, weight: weight)
        }
    }
}

public struct DynamicFontModifier: ViewModifier {
    public var size: CGFloat
    public var weight: Font.Weight
    public var fontType: FontType?
    public var scalable: Bool
    
    @AppStorage("appFontSize") private var level: Double = 0.0
    @AppStorage("appFontType") private var storedFontTypeRaw: String = FontType.alexandira.rawValue
    @Environment(\.appFontType) private var envFontType
    
    public init(size: CGFloat, weight: Font.Weight = .regular, fontType: FontType? = nil, scalable: Bool = true) {
        self.size = size
        self.weight = weight
        self.fontType = fontType
        self.scalable = scalable
    }
    
    public func body(content: Content) -> some View {
        content.font(
            .appFont(
                size: size,
                weight: weight,
                fontType: fontType,
                scalable: scalable,
                customLevel: level,
                overrideFontRaw: storedFontTypeRaw
            )
        )
    }
}

public extension View {
    func appFont(
        size: CGFloat = 14,
        weight: Font.Weight = .regular,
        fontType: FontType? = nil,
        scalable: Bool = true
    ) -> some View {
        self.modifier(DynamicFontModifier(size: size, weight: weight, fontType: fontType, scalable: scalable))
    }
}
