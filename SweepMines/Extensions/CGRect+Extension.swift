//
//  Created by ktiays on 2024/11/14.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import UIKit

extension CGRect {

    var center: CGPoint {
        .init(x: midX, y: midY)
    }

    var diagonal: CGFloat {
        sqrt(width * width + height * height)
    }

    func scaleBy(_ scale: CGFloat) -> CGRect {
        let newWidth = size.width * scale
        let newHeight = size.height * scale
        return .init(
            x: origin.x + (size.width - newWidth) / 2,
            y: origin.y + (size.height - newHeight) / 2,
            width: newWidth,
            height: newHeight
        )
    }
}

@_cdecl("adjustRectBoundedByContainer")
public func adjustRect(_ rect: CGRect, boundedBy container: CGRect) -> CGRect {
    // Center if too large
    if rect.width > container.width || rect.height > container.height {
        return CGRect(
            x: container.minX + (container.width - rect.width) / 2,
            y: container.minY + (container.height - rect.height) / 2,
            width: rect.width,
            height: rect.height
        )
    }
    
    var newRect = rect
    
    // Adjust x position
    if newRect.minX < container.minX {
        newRect.origin.x = container.minX
    } else if newRect.maxX > container.maxX {
        newRect.origin.x = container.maxX - newRect.width
    }
    
    // Adjust y position
    if newRect.minY < container.minY {
        newRect.origin.y = container.minY
    } else if newRect.maxY > container.maxY {
        newRect.origin.y = container.maxY - newRect.height
    }
    
    return newRect
}
