//
//  Created by ktiays on 2024/11/18.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI

func withLayerAnimation(_ animation: Spring, _ body: () -> Void) {
    LayerAnimatable.$curve.withValue(animation) {
        body()
    }
}

final class LayerAnimatable {

    @TaskLocal
    fileprivate static var curve: Spring? = nil

    private typealias AnimatedValue = (any VectorArithmetic & ApproximateEquatable)

    let layer: CALayer
    private var currentValues: [AnyHashable: AnimatedValue] = [:]
    private var animations: [AnyHashable: AnimationBase] = [:] {
        didSet {
            if animations.isEmpty {
                linkTarget?.invalidate()
                linkTarget = nil
                return
            }
            if linkTarget == nil {
                linkTarget = SharedDisplayLink.shared.add { [weak self] context in
                    self?.animate(with: context)
                }
            }
        }
    }
    var isAnimating: Bool { !animations.isEmpty }

    private var linkTarget: SharedDisplayLink.Target?

    deinit {
        linkTarget?.invalidate()
        linkTarget = nil
    }

    init(_ layer: CALayer) {
        self.layer = layer
    }

    func update<K, V>(value: V, for keyPath: KeyPath<AnimatablePropertyKeys, K>) where K: AnimatablePropertyKey, V == K.Value {
        update(value: value, for: AnimatablePropertyKeys()[keyPath: keyPath])
    }
    
    func update<K, V>(value: V, for key: K) where K: AnimatablePropertyKey, V == K.Value {
        let hashableKey = AnyHashable(key)
        guard let spring = Self.curve else {
            currentValues[hashableKey] = value
            key.apply(value: value, to: layer)
            return
        }

        if let previousAnimation = animations[hashableKey] as? Animation<V> {
            previousAnimation.target = value
            return
        }

        let currentValue: V = currentValues[hashableKey] as? V ?? .zero
        let animation = Animation(
            spring: spring,
            state: .init(value: currentValue, velocity: .zero, target: value)
        ) { [weak self] value in
            guard let layer = self?.layer else { return }
            self?.currentValues[hashableKey] = value
            key.apply(value: value, to: layer)
        }
        animations[hashableKey] = animation
    }

    private func animate(with context: SharedDisplayLink.Context) {
        let deltaTime = context.targetTimestamp - context.timestamp

        var removeKeys: Set<AnyHashable> = .init()
        for (key, animation) in animations {
            animation.update(deltaTime: deltaTime)
            if animation.isComplete {
                removeKeys.insert(key)
            }
        }
        for key in removeKeys {
            animations.removeValue(forKey: key)
        }
    }
}

extension LayerAnimatable {

    private class AnimationBase {

        var isComplete: Bool { true }

        func update(deltaTime: TimeInterval) {
            fatalError()
        }
    }

    private class Animation<V>: AnimationBase where V: VectorArithmetic & ApproximateEquatable {
        var delay: TimeInterval = 0
        var spring: Spring
        var state: AnimationState<V>
        let update: (V) -> Void

        var value: V {
            get { state.value }
            set { state.value = newValue }
        }
        var velocity: V {
            get { state.velocity }
            set { state.velocity = newValue }
        }
        var target: V {
            get { state.target }
            set { state.target = newValue }
        }
        override var isComplete: Bool {
            state.isComplete
        }

        init(spring: Spring, state: AnimationState<V>, update: @escaping (V) -> Void) {
            self.spring = spring
            self.state = state
            self.update = update
        }

        override func update(deltaTime: TimeInterval) {
            if state.isComplete { return }

            delay -= deltaTime
            if delay > 0 { return }

            var state = self.state
            spring.update(value: &state.value, velocity: &state.velocity, target: state.target, deltaTime: deltaTime)
            if state.isComplete {
                state.value = state.target
            }
            update(state.value)
            self.state = state
        }
    }
}
