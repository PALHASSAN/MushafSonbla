//
//  MushafImageCache.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

public final class MushafImageCache: @unchecked Sendable {
    public static let shared = MushafImageCache()
    
    #if canImport(UIKit) || canImport(AppKit)
    private let memoryCache = NSCache<NSNumber, PlatformImage>()
    
    private init() {
        memoryCache.countLimit = 30
    }
    
    public func image(forPage page: Int) -> PlatformImage? {
        memoryCache.object(forKey: NSNumber(value: page))
    }
    
    public func insertImage(_ image: PlatformImage, forPage page: Int) {
        memoryCache.setObject(image, forKey: NSNumber(value: page))
    }
    
    public func removeImage(forPage page: Int) {
        memoryCache.removeObject(forKey: NSNumber(value: page))
    }
    
    public func clearAll() {
        memoryCache.removeAllObjects()
    }
    #else
    private init() {}
    #endif
}
