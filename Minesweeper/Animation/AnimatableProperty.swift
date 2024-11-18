//
//  Created by ktiays on 2024/11/18.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import SwiftUI

protocol AnimatablePropertyKey: Hashable {
    
    associatedtype Value: VectorArithmetic & ApproximateEquatable
    
    func apply(value: Value, to target: CALayer)
}

struct CustomAnimatablePropertyKey<V: VectorArithmetic & ApproximateEquatable>: AnimatablePropertyKey {
    
    typealias Value = V
    
    let identifier: String
    let applier: (V, CALayer) -> Void
    
    static func == (lhs: CustomAnimatablePropertyKey<V>, rhs: CustomAnimatablePropertyKey<V>) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    func apply(value: V, to target: CALayer) {
        applier(value, target)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}


struct OpacityAnimatablePropertyKey: AnimatablePropertyKey {
    
    typealias Value = Float
    
    func apply(value: Float, to target: CALayer) {
        target.opacity = value
    }
}

struct LineWidthAnimatablePropertyKey: AnimatablePropertyKey {
    
    typealias Value = CGFloat
    
    func apply(value: CGFloat, to target: CALayer) {
        (target as? CAShapeLayer)?.lineWidth = value
    }
}

struct AnimatablePropertyKeys {
    
    let opacity: OpacityAnimatablePropertyKey = .init()
    let lineWidth: LineWidthAnimatablePropertyKey = .init()
}
