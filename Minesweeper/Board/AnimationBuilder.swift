//
//  Created by ktiays on 2024/11/13.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI
import UIKit

public enum AnimationValue<T> {
    case constant(T)
    case current

    func any() -> AnimationValue<Any> {
        switch self {
        case .constant(let value):
            return .constant(value)
        case .current:
            return .current
        }
    }

    func map<V>(_ transform: (T) -> V) -> AnimationValue<V> {
        switch self {
        case .constant(let value):
            return .constant(transform(value))
        case .current:
            return .current
        }
    }
}

extension CASpringAnimation {
    
    dynamic var settlingDuration: TimeInterval {
        set {
            setValue(newValue, forKey: "settlingDuration")
        }
        get {
            (value(forKey: "settlingDuration") as? TimeInterval) ?? 0
        }
    }
}

private func makeSpringAnimationWithSpring(_ spring: Spring) -> CASpringAnimation {
    let animation = CASpringAnimation()
    animation.damping = spring.damping
    animation.stiffness = spring.stiffness
    animation.mass = spring.mass
    animation.preferredFrameRateRange = .init(minimum: 80, maximum: 120, preferred: 120)
    animation.fillMode = .forwards
    animation.isRemovedOnCompletion = false
    animation.settlingDuration = spring.settlingDuration
    return animation
}

private func configureAnimation(
    _ animation: CABasicAnimation,
    with layer: CALayer,
    from fromValue: AnimationValue<Any>?,
    to toValue: Any?
) {
    let fromValue: Any? =
        if case let (.constant(value)) = fromValue {
            value
        } else {
            layer.presentation()?.value(forKeyPath: animation.keyPath!)
        }
    animation.fromValue = fromValue
    animation.toValue = toValue
}

public func springAnimation(_ spring: Spring) -> CASpringAnimation {
    makeSpringAnimationWithSpring(spring)
}

extension CALayer {
    
    public func opacityAnimation(
        _ spring: Spring,
        from fromValue: AnimationValue<CGFloat>,
        to toValue: CGFloat
    ) -> CASpringAnimation {
        let animation = makeSpringAnimationWithSpring(spring)
        animation.keyPath = "opacity"
        configureAnimation(animation, with: self, from: fromValue.any(), to: toValue)
        return animation
    }

    public func transformAnimation(
        _ spring: Spring,
        from fromValue: AnimationValue<CATransform3D>,
        to toValue: CATransform3D
    ) -> CASpringAnimation {
        let animation = makeSpringAnimationWithSpring(spring)
        animation.keyPath = "transform"
        configureAnimation(animation, with: self, from: fromValue.any(), to: toValue)
        return animation
    }

    public func contentsAnimation(
        _ spring: Spring,
        from fromValue: AnimationValue<CGImage>,
        to toValue: CGImage
    ) -> CASpringAnimation {
        let animation = makeSpringAnimationWithSpring(spring)
        animation.keyPath = "contents"
        configureAnimation(animation, with: self, from: fromValue.any(), to: toValue)
        return animation
    }

    public func scaleAnimation(
        _ spring: Spring,
        from fromValue: AnimationValue<CGFloat>,
        to toValue: CGFloat
    ) -> CASpringAnimation {
        transformAnimation(
            spring,
            from: fromValue.map {
                CATransform3DMakeScale($0, $0, 1)
            },
            to: CATransform3DMakeScale(toValue, toValue, 1)
        )
    }
    
    public func pathAnimation(
        _ spring: Spring,
        from fromValue: AnimationValue<CGPath>,
        to toValue: CGPath
    ) -> CASpringAnimation {
        let animation = makeSpringAnimationWithSpring(spring)
        animation.keyPath = "path"
        configureAnimation(animation, with: self, from: fromValue.any(), to: toValue)
        return animation
    }
    
    public func customKeyPathAnimation(
        _ spring: Spring,
        keyPath: String,
        from fromValue: AnimationValue<Any>,
        to toValue: Any
    ) -> CASpringAnimation {
        let animation = makeSpringAnimationWithSpring(spring)
        animation.keyPath = keyPath
        configureAnimation(animation, with: self, from: fromValue.any(), to: toValue)
        return animation
    }
    
    public func groupAnimation(with animations: [CAAnimation]) -> CAAnimationGroup {
        let group = CAAnimationGroup()
        group.animations = animations
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        return group
    }
}
