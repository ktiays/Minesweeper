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
