//
//  QuranPlayer.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/12/1447 AH.
//

import SwiftUI
import AVKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct QuranPlayer: View {
    @Bindable public var viewModel: QuranPlayerViewModel
    @State private var showReciterPicker = false
    @State private var showPlaybackRateSheet = false
    @Environment(\.colorScheme) private var colorScheme
    
    public var isLockedMode: Bool = false
    
    private let onPreviousVerse: (() -> Void)?
    private let onNextVerse: (() -> Void)?
    private let onPreviousChapter: (() -> Void)?
    private let onNextChapter: (() -> Void)?
    private let autoStart: Bool
    
    public init(
        viewModel: QuranPlayerViewModel,
        isLockedMode: Bool = false,
        autoStart: Bool = true,
        onPreviousVerse: (() -> Void)? = nil,
        onNextVerse: (() -> Void)? = nil,
        onPreviousChapter: (() -> Void)? = nil,
        onNextChapter: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.isLockedMode = isLockedMode
        self.autoStart = autoStart
        self.onPreviousVerse = onPreviousVerse
        self.onNextVerse = onNextVerse
        self.onPreviousChapter = onPreviousChapter
        self.onNextChapter = onNextChapter
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            headerRow
                .padding(.top, 30)
            
            progressBar
            
            controlsRow
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .glowBackground()
        .environment(\.layoutDirection, .rightToLeft)
        .task {
            guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
            viewModel.startIfNeeded(autoPlay: autoStart)
        }
        .sheet(isPresented: $showReciterPicker) {
            ReciterPickerView(
                reciters: ReciterService.shared.availableReciters,
                selectedReciter: ReciterService.shared.selectedReciter,
                onSelect: { reciter in
                    ReciterService.shared.selectReciter(reciter)
                    if let baseURL = reciter.audioBaseURL {
                        viewModel.updateReciter(
                            baseURL: baseURL,
                            reciterName: reciter.displayName,
                            reciterId: reciter.id,
                            timingSource: reciter.timingSource
                        )
                    }
                }
            )
            .presentationDetents([.large])
            .environment(\.layoutDirection, .rightToLeft)
        }
        .sheet(isPresented: $showPlaybackRateSheet) {
            PlaybackRateSheet(rate: $viewModel.playbackRate)
                .presentationDetents([.height(190)])
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
    
    private var headerRow: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                let reciterName = viewModel.reciterName.isEmpty ? "اختر القارئ" : viewModel.reciterName
                
                if isLockedMode {
                    Text(reciterName)
                        .appFont(size: 18, weight: .bold)
                        .foregroundStyle(colorScheme == .light ? .twNeutral800 : .twNeutral200)
                        .lineLimit(1)
                } else {
                    Button {
                        showReciterPicker.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Text(reciterName)
                                .appFont(size: 18, weight: .bold)
                                .foregroundStyle(colorScheme == .light ? .twNeutral800 : .twNeutral200)
                                .lineLimit(1)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.twNeutral500)
                        }
                    }
                    .buttonStyle(SpatialTouchPressStyle())
                }
                
                HStack(spacing: 6) {
                    Text(viewModel.chapterName)
                        .appFont(size: 24, weight: .medium, fontType: .sura)
                        .foregroundStyle(colorScheme == .light ? .twNeutral800 : .white)
                    
                    if let verseN = viewModel.currentVerseNumber, verseN > 0 {
                        Circle()
                            .fill(.twNeutral400.opacity(0.4))
                            .frame(width: 3, height: 3)
                        
                        Text("آية \(verseN.toArabic)")
                            .appFont(size: 12, weight: .medium)
                            .foregroundStyle(.twNeutral400)
                    }
                }
            }
            .transaction { $0.animation = nil }
            
            Spacer()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if viewModel.isBuffering {
                Text("تحميل…")
                    .appFont(size: 12, weight: .medium)
                    .foregroundStyle(.twNeutral400)
            }
        }
    }
    
    private var progressBar: some View {
        VStack(spacing: 5) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark ? .white.opacity(0.08) : .black.opacity(0.06))
                        .frame(height: 5)
                    
                    Capsule()
                        .fill(.twEmerald600)
                        .frame(width: max(0, min(geometry.size.width * CGFloat(viewModel.progress), geometry.size.width)), height: 5)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard viewModel.duration > 0 && !viewModel.isLoading else { return }
                            if !viewModel.isScrubbing { viewModel.beginScrubbing() }
                            
                            let rawRatio = min(max(value.location.x / geometry.size.width, 0), 1)
                            let ratio = 1.0 - rawRatio
                            
                            viewModel.updateScrubbing(progress: Double(ratio))
                        }
                        .onEnded { value in
                            guard viewModel.duration > 0 && !viewModel.isLoading else { return }
                            
                            let rawRatio = min(max(value.location.x / geometry.size.width, 0), 1)
                            let ratio = 1.0 - rawRatio
                            
                            viewModel.endScrubbing(progress: Double(ratio))
                        }
                )
            }
            .frame(height: 5)
            
            HStack {
                Text(viewModel.currentTime.formatTime)
                    .appFont(size: 11, weight: .medium, scalable: false)
                    .foregroundStyle(.twNeutral400)
                
                Spacer()
                
                Text("-\(viewModel.remainingTime.formatTime)")
                    .appFont(size: 11, weight: .medium, scalable: false)
                    .foregroundStyle(.twNeutral400)
            }
            .transaction { $0.animation = nil }
        }
    }

    private var controlsRow: some View {
        HStack(spacing: 0) {
            Button {
                showPlaybackRateSheet.toggle()
            } label: {
                Text(String(format: "%.2fx", viewModel.playbackRate))
                    .appFont(size: 12, weight: .bold, scalable: false)
                    .foregroundStyle(viewModel.playbackRate != 1.0 ? .twEmerald600 : .twNeutral400)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(viewModel.playbackRate != 1.0 ? .twEmerald600.opacity(0.12) : .clear)
                    )
            }
            .buttonStyle(SpatialTouchPressStyle())

            Spacer()

            HStack(spacing: 24) {
                Button {
                    onPreviousVerse?()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(onPreviousVerse == nil ? .twNeutral400.opacity(0.3) : (colorScheme == .dark ? .white : .twNeutral800))
                }
                .disabled(onPreviousVerse == nil || viewModel.isLoading)
                .buttonStyle(SpatialTouchPressStyle())

                Button(action: viewModel.togglePlayback) {
                    SectionBadge(fontSize: 32, systemIcon: viewModel.isPlaying ? "pause.fill" : "play.fill")
                }
                .buttonStyle(SpatialTouchPressStyle())
                .disabled(viewModel.isLoading && !viewModel.isPlaying)

                Button {
                    onNextVerse?()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(onNextVerse == nil ? .twNeutral400.opacity(0.3) : (colorScheme == .dark ? .white : .twNeutral800))
                }
                .disabled(onNextVerse == nil || viewModel.isLoading)
                .buttonStyle(SpatialTouchPressStyle())
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: viewModel.toggleRepeat) {
                    Image(systemName: viewModel.isRepeatEnabled ? "repeat.circle.fill" : "repeat")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(viewModel.isRepeatEnabled ? .twEmerald600 : .twNeutral400)
                }
                .buttonStyle(SpatialTouchPressStyle())

                #if os(iOS)
                AirPlayRoutePickerView()
                    .frame(width: 22, height: 22)
                #endif
            }
        }
    }
}

struct ReciterPickerView: View {
    let reciters: [ReciterService.ReciterInfo]
    let selectedReciter: ReciterService.ReciterInfo?
    let onSelect: (ReciterService.ReciterInfo) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var searchText: String = ""

    var filteredReciters: [ReciterService.ReciterInfo] {
        if searchText.isEmpty {
            return reciters
        } else {
            return reciters.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(Array(filteredReciters.enumerated()), id: \.element.id) { index, reciter in
                        let isSelected = reciter.id == selectedReciter?.id

                        Button {
                            onSelect(reciter)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundStyle(isSelected ? .twEmerald600 : (colorScheme == .light ? .twNeutral300 : .twNeutral600))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reciter.displayName)
                                        .appFont(weight: isSelected ? .bold : .medium)
                                        .foregroundStyle(colorScheme == .light ? .twNeutral800 : .twNeutral200)

                                    Text(reciter.rewaya)
                                        .appFont(size: 11, weight: .medium)
                                        .foregroundStyle(.twNeutral400)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(SpatialTouchPressStyle())

                        if index < filteredReciters.count - 1 {
                            Rectangle()
                                .fill(colorScheme == .dark ? .white.opacity(0.06) : .black.opacity(0.05))
                                .frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .appCard(radius: 18)
                .padding(.horizontal)
                .padding(.vertical, 16)
                .entranceTransition(order: 0)
            }
            .glowBackground()
            .searchable(text: $searchText, prompt: "البحث باسم القارئ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("تم") { dismiss() }
                        .appFont(size: 16, weight: .bold, scalable: false)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct PlaybackRateSheet: View {
    @Binding var rate: Float
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @Namespace private var rateAnimation

    let rates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("سرعة التلاوة")
                    .appFont(size: 20, weight: .bold)
                    .foregroundStyle(colorScheme == .dark ? .white : .twNeutral800)

                Spacer()

                Text(String(format: "%.2fx", rate))
                    .appFont(size: 13, weight: .bold, scalable: false)
                    .foregroundStyle(.twEmerald600)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(.twEmerald600.opacity(0.12))
                    )
            }
            .entranceTransition(order: 0)

            HStack(spacing: 4) {
                ForEach(rates, id: \.self) { r in
                    let isSelected = abs(rate - r) < 0.01

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            rate = r
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            dismiss()
                        }
                    } label: {
                        Text(String(format: "%.2f", r))
                            .appFont(size: 13, weight: isSelected ? .bold : .medium, scalable: false)
                            .foregroundStyle(isSelected ? (colorScheme == .dark ? .white : .twNeutral800) : .twNeutral400)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background {
                                if isSelected {
                                    Capsule()
                                        .fill(colorScheme == .dark ? .white.opacity(0.12) : .black.opacity(0.08))
                                        .matchedGeometryEffect(id: "ActivePlaybackRatePill", in: rateAnimation)
                                }
                            }
                    }
                    .buttonStyle(SpatialTouchPressStyle())
                }
            }
            .padding(4)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? .white.opacity(0.04) : .black.opacity(0.03))
            )
            .entranceTransition(order: 1)
            
            Spacer()
        }
        .padding(24)
        .glowBackground()
        .environment(\.layoutDirection, .rightToLeft)
    }
}

#if os(iOS)
public struct AirPlayRoutePickerView: UIViewRepresentable {
    public init() {}

    public func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = .systemGray
        picker.activeTintColor = UIColor(.twEmerald600)
        picker.prioritizesVideoDevices = false
        return picker
    }

    public func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
#endif

public extension Color {
    init(hex: String) {
        var cleanHexCode = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanHexCode = cleanHexCode.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: cleanHexCode).scanHexInt64(&rgb)
        let redValue = Double((rgb >> 16) & 0xFF) / 255.0
        let greenValue = Double((rgb >> 8) & 0xFF) / 255.0
        let blueValue = Double(rgb & 0xFF) / 255.0
        self.init(red: redValue, green: greenValue, blue: blueValue)
    }
}


extension Double {
    var formatTime: String {
        guard self.isFinite && self > 0 else { return "00:00" }
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    QuranPlayer(
        viewModel: QuranPlayerViewModel(),
        autoStart: false,
        onPreviousVerse: {},
        onNextVerse: {}
    )
    .frame(height: 260)
    .environment(\.layoutDirection, .rightToLeft)
}
