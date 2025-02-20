//
//  Created by ktiays on 2024/11/18.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import SwiftUI

protocol ApproximateEquatable {
    static func isApproximatelyEqual(_ lhs: Self, _ rhs: Self) -> Bool
}

extension CGFloat: ApproximateEquatable {
    static func isApproximatelyEqual(_ lhs: Self, _ rhs: Self) -> Bool {
        abs(lhs - rhs) < 1e-3
    }
}

extension Float: ApproximateEquatable {
    static func isApproximatelyEqual(_ lhs: Self, _ rhs: Self) -> Bool {
        abs(lhs - rhs) < 1e-3
    }
}

extension Double: ApproximateEquatable {
    static func isApproximatelyEqual(_ lhs: Self, _ rhs: Self) -> Bool {
        abs(lhs - rhs) < 1e-3
    }
}

extension AnimatablePair: ApproximateEquatable where First: ApproximateEquatable, Second: ApproximateEquatable {
    static func isApproximatelyEqual(_ lhs: AnimatablePair<First, Second>, _ rhs: AnimatablePair<First, Second>) -> Bool {
        First.isApproximatelyEqual(lhs.first, rhs.first) && Second.isApproximatelyEqual(lhs.second, rhs.second)
    }
}
