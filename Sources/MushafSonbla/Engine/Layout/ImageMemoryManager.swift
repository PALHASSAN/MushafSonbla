//
//  ImageMemoryManager.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

#if canImport(UIKit)
import UIKit
import SwiftUI
import ImageIO

public actor ImageMemoryManager {
    public static let shared = ImageMemoryManager()
    
    private var imageCache: [NSString: UIImage] = [:]
    private var activeTasks: [NSString: Task<UIImage?, Never>] = [:]
    private var keysPerPage: [Int: Set<NSString>] = [:]
    
    private init() {}
    
    public func loadImage(page: Int, line: Int, maxPixelSize: CGFloat) async -> UIImage? {
        let key = "\(page)_\(line)" as NSString
        
        if let cached = imageCache[key] { return cached }
        if let existingTask = activeTasks[key] { return await existingTask.value }
        
        let task = Task { () -> UIImage? in
            guard !Task.isCancelled else { return nil }
            
            let subdirectory = "quranImages/\(page)"
            guard let url = Bundle.module.url(
                forResource: "\(line)",
                withExtension: "png",
                subdirectory: subdirectory
            ) ?? Bundle.module.url(
                forResource: "\(line)",
                withExtension: "png"
            ) else {
                return nil
            }
            
            return await Task.detached(priority: .userInitiated) {
                return autoreleasepool {
                    guard let downsampled = Self.downsample(imageAt: url, maxPixelSize: maxPixelSize) else { return nil }
                    if let prepared = downsampled.preparingForDisplay() {
                        return prepared.withRenderingMode(.alwaysTemplate)
                    }
                    return downsampled.withRenderingMode(.alwaysTemplate)
                }
            }.value
        }
        
        activeTasks[key] = task
        let image = await task.value
        
        activeTasks[key] = nil
        
        if let finalImage = image, !Task.isCancelled {
            imageCache[key] = finalImage
            
            var keys = keysPerPage[page] ?? []
            keys.insert(key)
            keysPerPage[page] = keys
        }
        
        return image
    }
    
    public func pruneCache(keepingAround currentPage: Int) {
        let keptRange = (currentPage - 1)...(currentPage + 1)
        
        for (page, keys) in keysPerPage {
            if !keptRange.contains(page) {
                for key in keys {
                    imageCache[key] = nil
                }
                keysPerPage[page] = nil
            }
        }
    }
    
    public func clearCache() {
        imageCache.removeAll()
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
        keysPerPage.removeAll()
    }
    
    private nonisolated static func downsample(imageAt url: URL, maxPixelSize: CGFloat) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else { return nil }
        
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else { return nil }
        return UIImage(cgImage: downsampledImage)
    }
}
#endif
