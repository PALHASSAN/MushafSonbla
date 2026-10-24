//
//  QuranGuideSheet.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI

struct QuranGuideSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                    .entranceTransition(order: 0)

                LongPressActionSheetCard()
                    .entranceTransition(order: 1)

                DoubleTapBookmarkCard()
                    .entranceTransition(order: 2)

                PageTurnNavigationCard()
                    .entranceTransition(order: 3)
            }
            .padding(.horizontal)
            .padding(.vertical, 24)
        }
        .glowBackground()
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 14) {
            SectionBadge(fontSize: 24, systemIcon: "book.pages.fill")

            VStack(alignment: .leading, spacing: 8) {
                Text("دليل استخدام المصحف")
                    .appFont(size: 20, weight: .bold)
                    .foregroundStyle(colorScheme == .dark ? .white : .twNeutral800)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)

                Text("إرشادات تفاعلية لإدارة الفواصل، تشغيل التلاوات الصوتية، والتنقل بين الصفحات.")
                    .appFont(size: 13, weight: .medium)
                    .foregroundStyle(.twNeutral400)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
            }
        }
    }
}

private struct LongPressActionSheetCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isPressing: Bool = false
    @State private var isSheetPresented: Bool = false
    @State private var pressProgress: CGFloat = 0.0

    private let bookmarkHexColors: [Color] = [
        .twEmerald600, .twBlue600, .twAmber600, .twPurple600, .twRose600, .twTeal600
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? .white.opacity(0.03) : .black.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(colorScheme == .dark ? .white.opacity(0.08) : .black.opacity(0.06), lineWidth: 1)
                    )
                    .frame(height: 135)

                VStack(spacing: 8) {
                    Capsule()
                        .fill(.twNeutral400.opacity(0.25))
                        .frame(width: 170, height: 4.5)

                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isPressing ? .twEmerald600.opacity(0.16) : .clear)
                            .frame(height: 22)

                        HStack(spacing: 8) {
                            Capsule()
                                .fill(isPressing ? .twEmerald600 : .twNeutral400.opacity(0.4))
                                .frame(width: 125, height: 4.5)

                            Circle()
                                .strokeBorder(isPressing ? .twEmerald600 : .twNeutral400.opacity(0.4), lineWidth: 1.5)
                                .frame(width: 10, height: 10)
                        }
                    }

                    Capsule()
                        .fill(.twNeutral400.opacity(0.25))
                        .frame(width: 150, height: 4.5)

                    Capsule()
                        .fill(.twNeutral400.opacity(0.15))
                        .frame(width: 100, height: 4.5)
                }
                .padding(.bottom, 46)

                if isPressing && !isSheetPresented {
                    ZStack {
                        Circle()
                            .stroke(.twEmerald600.opacity(0.2), lineWidth: 2)
                            .frame(width: 30, height: 30)

                        Circle()
                            .trim(from: 0, to: pressProgress)
                            .stroke(.twEmerald600, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 30, height: 30)
                            .rotationEffect(.degrees(-90))

                        Circle()
                            .fill(.twEmerald600.opacity(0.2))
                            .frame(width: 20, height: 20)
                    }
                    .offset(y: -54)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }

                VStack(spacing: 7) {
                    Capsule()
                        .fill(colorScheme == .dark ? .white.opacity(0.25) : .black.opacity(0.2))
                        .frame(width: 24, height: 3)
                        .padding(.top, 5)

                    HStack(spacing: 8) {
                        ForEach(bookmarkHexColors.indices, id: \.self) { idx in
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(bookmarkHexColors[idx])
                        }
                    }
                    .padding(.top, 1)

                    HStack(spacing: 0) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.twEmerald600)

                            Text("تشغيل")
                                .appFont(size: 8, weight: .bold, scalable: false)
                                .foregroundStyle(colorScheme == .dark ? .white : .twNeutral800)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)

                        Rectangle()
                            .fill(colorScheme == .dark ? .white.opacity(0.15) : .black.opacity(0.1))
                            .frame(width: 1, height: 10)

                        HStack(spacing: 3) {
                            Text("القارئ")
                                .appFont(size: 8, weight: .bold, scalable: false)
                                .foregroundStyle(.twNeutral400)

                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 6))
                                .foregroundStyle(.twNeutral400)
                        }
                        .padding(.horizontal, 6)
                    }
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? .white.opacity(0.06) : .black.opacity(0.04))
                    )
                    .padding(.bottom, 7)
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(colorScheme == .dark ? .white.opacity(0.15) : .black.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 14)
                .offset(y: isSheetPresented ? 0 : 90)
                .opacity(isSheetPresented ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .clipped()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("قائمة خيارات الآية")
                        .appFont(size: 16, weight: .bold, scalable: false)
                        .foregroundStyle(colorScheme == .dark ? .white : .twNeutral800)

                    Spacer()

                    SectionBadge(textColor: .twEmerald600, systemIcon: "hand.tap.fill")
                }

                Text("اضغط مطولًا على أي آية لفتح قائمة الخيارات لإضافة فاصل مرجعي ملون، أو بدء الاستماع للتلاوة مباشرة.")
                    .appFont(scalable: false)
                    .foregroundStyle(.twNeutral400)
                    .lineSpacing(6)
            }
        }
        .padding(16)
        .appCard(radius: 20)
        .animation(SheetMotion.stateSpring, value: isSheetPresented)
        .animation(SheetMotion.gentleEase, value: isPressing)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.4))

                withAnimation(.easeInOut(duration: 0.18)) {
                    isPressing = true
                }
                withAnimation(.linear(duration: 0.95)) {
                    pressProgress = 1.0
                }
                try? await Task.sleep(for: .milliseconds(980))

                withAnimation(SheetMotion.entranceSpring) {
                    isSheetPresented = true
                }

                try? await Task.sleep(for: .seconds(2.8))

                withAnimation(SheetMotion.gentleEase) {
                    isSheetPresented = false
                    isPressing = false
                    pressProgress = 0.0
                }
            }
        }
    }
}

private struct DoubleTapBookmarkCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isHighlighted: Bool = true
    @State private var tapTrigger: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? .white.opacity(0.03) : .black.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(colorScheme == .dark ? .white.opacity(0.08) : .black.opacity(0.06), lineWidth: 1)
                    )
                    .frame(height: 94)

                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isHighlighted ? .twBlue600 : .clear)
                        .frame(width: 4, height: 42)

                    VStack(alignment: .leading, spacing: 7) {
                        Capsule()
                            .fill(isHighlighted ? .twBlue600.opacity(0.8) : .twNeutral400.opacity(0.35))
                            .frame(width: 155, height: 5.5)

                        HStack(spacing: 6) {
                            Capsule()
                                .fill(isHighlighted ? .twBlue600.opacity(0.55) : .twNeutral400.opacity(0.2))
                                .frame(width: 95, height: 5.5)

                            Circle()
                                .strokeBorder(isHighlighted ? .twBlue600 : .twNeutral400.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 9, height: 9)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isHighlighted ? .twBlue600.opacity(0.12) : .clear)
                )
                .padding(.horizontal, 16)

                Circle()
                    .stroke(.twBlue600, lineWidth: 2)
                    .frame(width: 26, height: 26)
                    .offset(x: 14)
                    .keyframeAnimator(initialValue: RippleValues(), trigger: tapTrigger) { view, val in
                        view
                            .scaleEffect(val.scale)
                            .opacity(val.opacity)
                    } keyframes: { _ in
                        KeyframeTrack(\.scale) {
                            CubicKeyframe(0.7, duration: 0.02)
                            CubicKeyframe(1.3, duration: 0.18)
                            CubicKeyframe(0.7, duration: 0.06)
                            CubicKeyframe(1.4, duration: 0.20)
                            SpringKeyframe(1.0, duration: 0.15)
                        }
                        KeyframeTrack(\.opacity) {
                            LinearKeyframe(0.75, duration: 0.05)
                            LinearKeyframe(0.0, duration: 0.15)
                            LinearKeyframe(0.0, duration: 0.06)
                            LinearKeyframe(0.85, duration: 0.05)
                            LinearKeyframe(0.0, duration: 0.20)
                        }
                    }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("إلغاء حفظ الآية")
                        .appFont(size: 16, weight: .bold, scalable: false)
                        .foregroundStyle(colorScheme == .dark ? .white : .twNeutral800)

                    Spacer()

                    SectionBadge(textColor: .twBlue600, systemIcon: "hand.tap")
                }

                Text("انقر نقرتين متتاليتين على أي آية مظللة لإزالة الحفظ والتظليل.")
                    .appFont(scalable: false)
                    .foregroundStyle(.twNeutral400)
                    .lineSpacing(6)
            }
        }
        .padding(16)
        .appCard(radius: 20)
        .animation(SheetMotion.stateSpring, value: isHighlighted)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.0))

                tapTrigger += 1
                try? await Task.sleep(for: .milliseconds(320))

                withAnimation(SheetMotion.stateSpring) {
                    isHighlighted = false
                }

                try? await Task.sleep(for: .seconds(2.8))

                withAnimation(SheetMotion.stateSpring) {
                    isHighlighted = true
                }
            }
        }
    }

    private struct RippleValues {
        var scale: CGFloat = 0.7
        var opacity: Double = 0.0
    }
}

private struct PageTurnNavigationCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var turnProgress: CGFloat = 0.0
    @State private var handOpacity: Double = 0.0

    private enum Layout {
        static let sheetWidth: CGFloat = 82
        static let sheetHeight: CGFloat = 114
        static let maxCurlAngle: Double = -36.0
        static let maxHorizontalCurl: CGFloat = -36.0
        static let handStart: CGFloat = 32.0
        static let handEnd: CGFloat = -26.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? .white.opacity(0.03) : .black.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                colorScheme == .dark ? .white.opacity(0.08) : .black.opacity(0.06),
                                lineWidth: 1
                            )
                    )
                    .frame(height: 138)

                ZStack {
                    quranSheetLeaf(pageNumber: "٥١", hasSurahHeader: false, linePattern: [52, 44, 58, 54, 48, 56, 44])
                        .scaleEffect(0.95)
                        .offset(y: -3.5)
                        .opacity(0.75)
                        .shadow(
                            color: .black.opacity(colorScheme == .dark ? 0.22 : 0.05),
                            radius: 4,
                            y: 2
                        )

                    quranSheetLeaf(pageNumber: "٥٠", hasSurahHeader: true, linePattern: [60, 52, 46, 48, 34, 56])
                        .rotation3DEffect(
                            .degrees(reduceMotion ? 0 : (Double(turnProgress) * Layout.maxCurlAngle)),
                            axis: (x: 0.0, y: 1.0, z: 0.06),
                            anchor: .leading,
                            perspective: 0.45
                        )
                        .offset(x: reduceMotion ? 0 : (turnProgress * Layout.maxHorizontalCurl))
                        .shadow(
                            color: .black.opacity(colorScheme == .dark ? 0.38 : 0.12),
                            radius: 7 + (turnProgress * 4),
                            x: -3 * turnProgress,
                            y: 3
                        )
                }

                if !reduceMotion {
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.indigo)
                        .shadow(
                            color: .black.opacity(colorScheme == .dark ? 0.35 : 0.15),
                            radius: 3,
                            y: 2
                        )
                        .offset(
                            x: Layout.handStart + (turnProgress * (Layout.handEnd - Layout.handStart)),
                            y: 30
                        )
                        .opacity(handOpacity)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("التنقل بين الصفحات")
                        .appFont(size: 16, weight: .bold, scalable: false)
                        .foregroundStyle(colorScheme == .dark ? .white : .twNeutral800)

                    Spacer()

                    SectionBadge(textColor: .indigo, systemIcon: "appwindow.swipe.rectangle")
                }

                Text("مرّر إصبعك أفقيًا يمينًا أو يسارًا لتقليب صفحات المصحف الشريف والانتقال بين السور بسلاسة.")
                    .appFont(scalable: false)
                    .foregroundStyle(.twNeutral400)
                    .lineSpacing(6)
            }
        }
        .padding(16)
        .appCard(radius: 20)
        .task {
            guard !reduceMotion else { return }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.0))
                guard !Task.isCancelled else { break }

                withAnimation(.easeOut(duration: 0.22)) {
                    handOpacity = 0.95
                }
                try? await Task.sleep(for: .milliseconds(120))
                guard !Task.isCancelled else { break }

                withAnimation(SheetMotion.settlingSpring) {
                    turnProgress = 1.0
                }
                try? await Task.sleep(for: .milliseconds(700))
                guard !Task.isCancelled else { break }

                withAnimation(.easeOut(duration: 0.25)) {
                    handOpacity = 0.0
                }
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { break }

                withAnimation(SheetMotion.gentleEase) {
                    turnProgress = 0.0
                }
            }
        }
    }

    private func quranSheetLeaf(pageNumber: String, hasSurahHeader: Bool, linePattern: [CGFloat]) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? .twNeutral900 : .white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            colorScheme == .dark ? .white.opacity(0.12) : .black.opacity(0.08),
                            lineWidth: 1.2
                        )
                )

            VStack(alignment: .leading, spacing: 5.5) {
                if hasSurahHeader {
                    Capsule()
                        .strokeBorder(.twEmerald600.opacity(colorScheme == .dark ? 0.7 : 0.6), lineWidth: 1)
                        .background(
                            Capsule()
                                .fill(.twEmerald600.opacity(colorScheme == .dark ? 0.15 : 0.08))
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 11)
                        .padding(.bottom, 2)
                }

                ForEach(linePattern.indices, id: \.self) { index in
                    Capsule()
                        .fill(colorScheme == .dark ? .white.opacity(0.24) : .black.opacity(0.22))
                        .frame(width: linePattern[index], height: 2.2)
                }

                Spacer(minLength: 0)

                Text(pageNumber)
                    .appFont(size: 10, weight: .semibold, scalable: false)
                    .foregroundStyle(colorScheme == .dark ? .twNeutral400 : .twNeutral500)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: Layout.sheetWidth, height: Layout.sheetHeight)
    }
}

#Preview {
    QuranGuideSheet()
}
