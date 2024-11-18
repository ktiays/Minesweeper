//
//  Created by ktiays on 2024/11/18.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI

struct AnimationState<T>: VectorArithmetic where T: VectorArithmetic {

    var value: T
    var velocity: T
    var target: T

    static var zero: AnimationState<T> {
        .init(value: .zero, velocity: .zero, target: .zero)
    }

    static func + (_ lhs: Self, _ rhs: Self) -> Self {
        .init(value: lhs.value + rhs.value, velocity: lhs.velocity + rhs.velocity, target: lhs.target + rhs.target)
    }

    static func - (_ lhs: Self, _ rhs: Self) -> Self {
        .init(value: lhs.value - rhs.value, velocity: lhs.velocity - rhs.velocity, target: lhs.target - rhs.target)
    }

    mutating func scale(by rhs: Double) {
        value.scale(by: rhs)
        velocity.scale(by: rhs)
        target.scale(by: rhs)
    }

    var magnitudeSquared: Double {
        value.magnitudeSquared + velocity.magnitudeSquared + target.magnitudeSquared
    }
}

extension AnimationState where T: ApproximateEquatable {

    var isComplete: Bool {
        T.isApproximatelyEqual(value, target) && T.isApproximatelyEqual(velocity, .zero)
    }
}
