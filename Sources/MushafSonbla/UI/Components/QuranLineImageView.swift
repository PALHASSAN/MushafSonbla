//
//  QuranLineImageView.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import SwiftUI

#if canImport(UIKit)
import UIKit

public struct QuranLineImageView: View {
    public let page: Int
    public let line: Int
    public let imageAspect: CGFloat
    public let containerWidth: CGFloat
    public let scaledImageHeight: CGFloat
    
    @AppStorage("quranTheme") private var quranTheme: String = "أبيض"
    @Environment(\.displayScale) private var displayScale

    @State private var loadedImage: UIImage? = nil

    public init(
        page: Int,
        line: Int,
        imageAspect: CGFloat,
        containerWidth: CGFloat,
        scaledImageHeight: CGFloat
    ) {
        self.page = page
        self.line = line
        self.imageAspect = imageAspect
        self.containerWidth = containerWidth
        self.scaledImageHeight = scaledImageHeight
    }

    public var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(imageAspect, contentMode: .fit)
                    .frame(width: containerWidth, height: scaledImageHeight)
                    .clipped()
                    .foregroundColor(textColor)
                    .allowsTightening(false)
            } else {
                Color.clear
                    .frame(width: containerWidth, height: scaledImageHeight)
            }
        }
        .task(id: "\(page)_\(line)") {
            await loadImageAsync()
        }
        .onDisappear {
            loadedImage = nil
        }
    }
    
    private var textColor: Color {
        if quranTheme == "ليلي" {
            return .white
        } else {
            return .twNeutral800
        }
    }
    
    @MainActor
    private func loadImageAsync() async {
        let maxPixels = containerWidth * displayScale
        let fetchedImage = await ImageMemoryManager.shared.loadImage(
            page: page,
            line: line,
            maxPixelSize: maxPixels
        )
        if !Task.isCancelled {
            self.loadedImage = fetchedImage
        }
    }
}
#endif
