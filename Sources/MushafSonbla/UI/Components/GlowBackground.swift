//
//  GlowBackground.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//


import SwiftUI

struct GlowBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.twNeutral900 : Color.twNeutral100)
                .ignoresSafeArea()

            GeometryReader { proxy in
                Circle()
                    .fill(.twEmerald600.opacity(colorScheme == .dark ? 0.12 : 0.05))
                    .frame(width: proxy.size.width * 0.95)
                    .blur(radius: 85)
                    .offset(x: -proxy.size.width * 0.25, y: -70)
                
                Circle()
                    .fill(.twEmerald400.opacity(colorScheme == .dark ? 0.08 : 0.03))
                    .frame(width: proxy.size.width * 0.8)
                    .blur(radius: 90)
                    .offset(x: proxy.size.width * 0.35, y: 180)
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

struct GlowBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                GlowBackground()
            }
    }
}

extension View {
    func glowBackground() -> some View {
        self.modifier(GlowBackgroundModifier())
    }
}
