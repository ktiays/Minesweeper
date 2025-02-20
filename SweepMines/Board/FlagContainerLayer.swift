//
//  Created by ktiays on 2024/11/13.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI
import UIKit

@MainActor
final class FlagContainerLayer: CALayer {

    typealias Flag = Minefield.Flag

    enum ChangeAnimation {
        /// Symbol slides in from the top.
        case top

        /// Symbol slides in from the bottom.
        case bottom
    }

    private struct AnimatedProperties: VectorArithmetic, ApproximateEquatable {
        var opacity: Double
        var blurRadius: Double
        var scale: Double
        var translation: Double

        static var zero: Self {
            .init(opacity: 0, blurRadius: 0, scale: 0, translation: 0)
        }

        static func - (lhs: Self, rhs: Self) -> Self {
            .init(
                opacity: lhs.opacity - rhs.opacity,
                blurRadius: lhs.blurRadius - rhs.blurRadius,
                scale: lhs.scale - rhs.scale,
                translation: lhs.translation - rhs.translation
            )
        }

        static func + (lhs: Self, rhs: Self) -> Self {
            .init(
                opacity: lhs.opacity + rhs.opacity,
                blurRadius: lhs.blurRadius + rhs.blurRadius,
                scale: lhs.scale + rhs.scale,
                translation: lhs.translation + rhs.translation
            )
        }

        static func isApproximatelyEqual(_ lhs: Self, _ rhs: Self) -> Bool {
            Double.isApproximatelyEqual(lhs.opacity, rhs.opacity)
                && Double.isApproximatelyEqual(lhs.blurRadius, rhs.blurRadius)
                && Double.isApproximatelyEqual(lhs.scale, rhs.scale)
                && Double.isApproximatelyEqual(lhs.translation, rhs.translation)
        }

        mutating func scale(by rhs: Double) {
            opacity.scale(by: rhs)
            blurRadius.scale(by: rhs)
            scale.scale(by: rhs)
            translation.scale(by: rhs)
        }

        var magnitudeSquared: Double {
            opacity * opacity + blurRadius * blurRadius + scale * scale + translation * translation
        }
    }

    private var linkTarget: SharedDisplayLink.Target?

    private(set) var flag: Flag = .none

    private lazy var flagLayer: CALayer = {
        let layer = makeBlurLayer()
        let cache = ImageManager.shared.cache
        layer.contents = cache.flag
        return layer
    }()
    private lazy var maybeLayer: CALayer = {
        let layer = makeBlurLayer()
        let cache = ImageManager.shared.cache
        layer.contents = cache.maybe
        return layer
    }()
    private var loadedLayers: Set<CALayer> = .init()

    private let curve: Spring = .init(response: 0.3, dampingRatio: 0.7)
    private var isAnimating: Bool = false
    private var appearingLayer: CALayer?
    private var disappearingLayer: CALayer?
    private var animationStates: [CALayer: AnimationState<AnimatedProperties>] = [:]
    private var layerProperties: [CALayer: AnimatedProperties] = .init()

    private var animationOffset: CGFloat {
        bounds.height * 0.3
    }

    deinit {
        linkTarget?.invalidate()
        linkTarget = nil
    }

    private func makeBlurLayer() -> CALayer {
        let layer = CALayer()
        layer.delegate = self
        layer.allowsEdgeAntialiasing = true
        if let blurFilter = GaussianBlurFilter() {
            layer.filters = [blurFilter.effect]
        }
        return layer
    }

    override func layoutSublayers() {
        super.layoutSublayers()

        let flagScale: CGFloat = 0.6

        loadedLayers.forEach {
            let transform = $0.transform
            $0.transform = CATransform3DIdentity
            $0.frame = bounds.scaleBy(flagScale)
            $0.transform = transform
        }
    }

    private func layer(for flag: Flag) -> CALayer? {
        switch flag {
        case .flag:
            flagLayer
        case .maybe:
            maybeLayer
        default:
            nil
        }
    }

    func changeFlag(to flag: Flag, with animation: ChangeAnimation = .bottom) {
        if flag == self.flag {
            return
        }

        if linkTarget == nil {
            linkTarget = SharedDisplayLink.shared.add { [weak self] in
                self?.handleVsync($0)
            }
        }

        let appearOffset: CGFloat = (animation == .top ? -0.2 : 0.2)
        let disappearOffset: CGFloat = (animation == .top ? 0.1 : -0.1)

        let prepareAppearProperties = AnimatedProperties(
            opacity: 0,
            blurRadius: 5,
            scale: 0.2,
            translation: appearOffset
        )
        let targetProperties = AnimatedProperties(
            opacity: 1,
            blurRadius: 0,
            scale: 1,
            translation: 0
        )
        let prepareDisappearProperties = AnimatedProperties(
            opacity: 0,
            blurRadius: 5,
            scale: 0.2,
            translation: disappearOffset
        )

        func addLayerIfNeeded(_ layer: CALayer) {
            if layer.superlayer != nil {
                return
            }
            layer.opacity = 0
            addSublayer(layer)
            loadedLayers.insert(layer)
        }

        func properties(for layer: CALayer, orInsert value: AnimatedProperties) -> AnimatedProperties {
            if let properties = layerProperties[layer] {
                return properties
            }
            layerProperties[layer] = value
            return value
        }

        if let currentLayer = layer(for: self.flag) {
            addLayerIfNeeded(currentLayer)
            disappearingLayer = currentLayer
            let velocity = animationStates[currentLayer]?.velocity ?? .zero
            let properties = properties(for: currentLayer, orInsert: targetProperties)
            let state = AnimationState(
                value: properties,
                velocity: velocity,
                target: prepareDisappearProperties
            )
            animationStates[currentLayer] = state
        }
        if let targetLayer = layer(for: flag) {
            addLayerIfNeeded(targetLayer)
            appearingLayer = targetLayer
            let velocity = animationStates[targetLayer]?.velocity ?? .zero
            let state = AnimationState(
                value: prepareAppearProperties,
                velocity: velocity,
                target: targetProperties
            )
            animationStates[targetLayer] = state
        }

        self.flag = flag
        isAnimating = true
    }

    override func action(forKey event: String) -> (any CAAction)? {
        null
    }

    private func handleVsync(_ context: SharedDisplayLink.Context) {
        if !isAnimating { return }

        if appearingLayer == nil && disappearingLayer == nil {
            logger.error("No layers to animate")
            assertionFailure()
            self.animationStates.removeAll()
            return
        }

        let duration = context.targetTimestamp - context.timestamp

        var appearingComplete = false
        var disappearingComplete = false
        if let appearingLayer, var appearingState = animationStates[appearingLayer] {
            updateLayer(appearingLayer, with: &appearingState, deltaTime: duration)
            animationStates[appearingLayer] = appearingState
            appearingComplete = appearingState.isComplete
        } else {
            appearingComplete = true
        }

        if let disappearingLayer, var disappearingState = animationStates[disappearingLayer] {
            updateLayer(disappearingLayer, with: &disappearingState, deltaTime: duration)
            animationStates[disappearingLayer] = disappearingState
            disappearingComplete = disappearingState.isComplete
        } else {
            disappearingComplete = true
        }

        if appearingComplete && disappearingComplete {
            isAnimating = false
            self.animationStates.removeAll()
            self.appearingLayer = nil
            if let layer = disappearingLayer {
                self.layerProperties.removeValue(forKey: layer)
                self.disappearingLayer = nil
            }
        }
    }

    private func updateLayer(
        _ layer: CALayer,
        with state: inout AnimationState<AnimatedProperties>,
        deltaTime: TimeInterval
    ) {
        curve.update(
            value: &state.value,
            velocity: &state.velocity,
            target: state.target,
            deltaTime: deltaTime
        )

        let properties = state.value
        layer.opacity = Float(properties.opacity)
        layer.setValue(properties.blurRadius, forKeyPath: GaussianBlurFilter.inputRadiusKeyPath)
        let height = bounds.height
        layer.transform = CATransform3DConcat(
            CATransform3DMakeScale(CGFloat(properties.scale), CGFloat(properties.scale), 1),
            CATransform3DMakeTranslation(0, CGFloat(properties.translation * height), 0)
        )
        layerProperties[layer] = properties
    }
}

extension FlagContainerLayer: CALayerDelegate {

    nonisolated func action(for layer: CALayer, forKey event: String) -> (any CAAction)? {
        null
    }
}
