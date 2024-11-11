//
//  Created by ktiays on 2024/11/11.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import Foundation

@MainActor
final class ImageManager {
    
    static let shared = ImageManager()
    
    let lightCache: ImageCache = .init(colorScheme: .light)
    let darkCache: ImageCache = .init(colorScheme: .dark)
    
    var cache: ImageCache {
        UITraitCollection.current.userInterfaceStyle == .dark ? darkCache : lightCache
    }
}
