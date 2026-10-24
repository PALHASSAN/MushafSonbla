//
//  SheetMotion.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//


import SwiftUI

enum SheetMotion {
    static let entranceSpring = Animation.spring(response: 0.48, dampingFraction: 0.82)
    static let stateSpring    = Animation.spring(response: 0.65, dampingFraction: 0.80)
    static let settlingSpring = Animation.spring(response: 0.75, dampingFraction: 0.72)
    static let pageCurlSpring = Animation.spring(response: 0.70, dampingFraction: 0.78)
    static let gentleEase     = Animation.easeInOut(duration: 0.45)
}

struct AutomaticEntranceModifier: ViewModifier {
    let order: Int
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared: Bool = false

    private var targetOffset: CGFloat {
        14.0 + CGFloat(order) * 1.5
    }

    private var staggerDelay: Double {
        let clampedOrder = min(order, 5)
        return 0.05 + Double(clampedOrder) * 0.065
    }

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .compositingGroup()
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : targetOffset)
                .animation(
                    SheetMotion.entranceSpring.delay(staggerDelay),
                    value: hasAppeared
                )
                .onAppear {
                    guard !hasAppeared else { return }
                    DispatchQueue.main.async {
                        hasAppeared = true
                    }
                }
        }
    }
}

struct CardEntranceModifier: ViewModifier {
    let order: Int
    let hasAppeared: Bool
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var targetOffset: CGFloat {
        14.0 + CGFloat(order) * 1.5
    }

    private var staggerDelay: Double {
        let clampedOrder = min(order, 5)
        return 0.05 + Double(clampedOrder) * 0.065
    }
    
    func body(content: Content) -> some View {
        if reduceMotion {
            content
                .opacity(hasAppeared ? 1 : 0)
        } else {
            content
                .compositingGroup()
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : targetOffset)
                .animation(
                    SheetMotion.entranceSpring.delay(staggerDelay),
                    value: hasAppeared
                )
        }
    }
}

struct DynamicCardEntranceModifier<T: Equatable>: ViewModifier {
    let order: Int
    let trigger: T

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible: Bool = false

    private var targetOffset: CGFloat {
        14.0 + CGFloat(order) * 1.5
    }

    private var staggerDelay: Double {
        let clampedOrder = min(order, 5)
        return 0.05 + Double(clampedOrder) * 0.065
    }

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .compositingGroup()
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : targetOffset)
                .animation(
                    SheetMotion.entranceSpring.delay(staggerDelay),
                    value: isVisible
                )
                .onAppear {
                    isVisible = true
                }
                .onChange(of: trigger) {
                    isVisible = false
                    DispatchQueue.main.async {
                        isVisible = true
                    }
                }
        }
    }
}

extension View {
    func entranceTransition(order: Int) -> some View {
        modifier(AutomaticEntranceModifier(order: order))
    }
    
    func entranceTransition(order: Int, hasAppeared: Bool) -> some View {
        modifier(CardEntranceModifier(order: order, hasAppeared: hasAppeared))
    }

    func entranceTransition<T: Equatable>(order: Int, trigger: T) -> some View {
        modifier(DynamicCardEntranceModifier(order: order, trigger: trigger))
    }
}
