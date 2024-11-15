//
//  Created by ktiays on 2024/11/14.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import UIKit

func - (_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
    .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func * (_ lhs: CGPoint, _ rhs: CGFloat) -> CGPoint {
    .init(x: lhs.x * rhs, y: lhs.y * rhs)
}

extension CGPoint {

    var length: CGFloat {
        sqrt(x * x + y * y)
    }
}
