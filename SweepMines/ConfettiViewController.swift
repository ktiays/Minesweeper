//
//  Created by ktiays on 2022/5/16.
//  Copyright (c) 2022 ktiays. All rights reserved.
//

import UIKit
import ObjectiveC

extension CAEmitterLayer {

    func setBehaviors(_ behaviors: [Any]) {
        setValue(behaviors, forKey: "emitterBehaviors")
    }
}

func emitterBehavior(with type: String) -> NSObject {
    let behaviorClass = NSClassFromString("CAEmitterBehavior") as! NSObject.Type
    let behaviorWithType = behaviorClass.method(for: NSSelectorFromString("behaviorWithType:"))!
    let castedBehaviorWithType = unsafeBitCast(behaviorWithType, to: (@convention(c) (Any?, Selector, Any?) -> NSObject).self)
    return castedBehaviorWithType(behaviorClass, NSSelectorFromString("behaviorWithType:"), type)
}

final class ConfettiViewController: UIViewController {

    private let confettiColors: [UIColor] = [
        .init(red: 149.0 / 255, green: 58.0 / 255, blue: 1, alpha: 1),
        .init(red: 1, green: 195.0 / 255, blue: 41.0 / 255, alpha: 1),
        .init(red: 1, green: 101.0 / 255, blue: 26.0 / 255, alpha: 1),
        .init(red: 1, green: 47.0 / 255, blue: 39.0 / 255, alpha: 1),
        .init(red: 1, green: 91.0 / 255, blue: 134.0 / 255, alpha: 1),
        .init(red: 233.0 / 255, green: 122.0 / 255, blue: 208.0 / 255, alpha: 1),
        .init(red: 123.0 / 255, green: 92.0 / 255, blue: 1, alpha: 1),
        .init(red: 76.0 / 255, green: 126.0 / 255, blue: 1, alpha: 1),
        .init(red: 71.0 / 255, green: 192.0 / 255, blue: 1, alpha: 1),
    ]

    private enum ConfettiShape {
        case rectangle
        case circle
    }

    private enum EmitterLocation {
        case bottomLeft
        case bottomRight
    }

    private lazy var confettiCells: [CAEmitterCell] = [ConfettiShape.rectangle, ConfettiShape.circle].flatMap { shape in
        confettiColors.compactMap { color in
            // Draw shap
            let imageRect: CGRect = {
                switch shape {
                case .rectangle:
                    return CGRect(x: 0, y: 0, width: 20, height: 13)
                case .circle:
                    return CGRect(x: 0, y: 0, width: 10, height: 10)
                }
            }()
            
            UIGraphicsBeginImageContextWithOptions(imageRect.size, false, UIScreen.main.scale)
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(color.cgColor)

            switch shape {
            case .rectangle:
                context?.fill(imageRect)
            case .circle:
                context?.fillEllipse(in: imageRect)
            }
            
            let uiImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            // Create cell
            let emitterCell = CAEmitterCell()
            emitterCell.name = UUID().uuidString
            emitterCell.beginTime = 0.1
            emitterCell.birthRate = 160
            emitterCell.contents = uiImage?.cgImage
            emitterCell.emissionRange = .pi
            emitterCell.lifetime = 10
            emitterCell.spin = 4
            emitterCell.spinRange = 8
            emitterCell.velocityRange = 0
            emitterCell.yAcceleration = 0
            emitterCell.scale = 0.2

            emitterCell.setValue("plane", forKey: "particleType")
            emitterCell.setValue(Double.pi, forKey: "orientationRange")
            emitterCell.setValue(Double.pi / 2, forKey: "orientationLongitude")
            emitterCell.setValue(Double.pi / 2, forKey: "orientationLatitude")

            return emitterCell
        }
    }

    private lazy var horizontalWaveBehavior: Any = {
        let behavior = emitterBehavior(with: "wave")
        behavior.setValue([100, 0, 0], forKeyPath: "force")
        behavior.setValue(0.5, forKeyPath: "frequency")
        return behavior
    }()

    private lazy var verticalWaveBehavior: Any = {
        let behavior = emitterBehavior(with: "wave")
        behavior.setValue([0, 500, 0], forKeyPath: "force")
        behavior.setValue(3, forKeyPath: "frequency")
        return behavior
    }()

    private lazy var dragBehavior: Any = {
        let behavior = emitterBehavior(with: "drag")
        behavior.setValue("dragBehavior", forKey: "name")
        behavior.setValue(1.8, forKey: "drag")
        return behavior
    }()

    private func attractorBehavior(for layer: CAEmitterLayer, in location: EmitterLocation) -> Any {
        let behavior = emitterBehavior(with: "attractor")
        behavior.setValue("attractor", forKeyPath: "name")

        // Attractiveness
        behavior.setValue(-200, forKeyPath: "falloff")
        behavior.setValue(400, forKeyPath: "radius")
        behavior.setValue(10, forKeyPath: "stiffness")

        // Position
        behavior.setValue(
            CGPoint(
                x: layer.emitterPosition.x + 90 * (location == .bottomLeft ? -1 : 1),
                y: layer.emitterPosition.y + 114
            ),
            forKeyPath: "position"
        )
        behavior.setValue(-70, forKeyPath: "zPosition")
        return behavior
    }

    private lazy var bottomLeftLayer: CAEmitterLayer = makeConfettiLayer()
    private lazy var bottomRightLayer: CAEmitterLayer = makeConfettiLayer()

    private var isEmitterLayerConfigured: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
        
        view.layer.addSublayer(bottomLeftLayer)
        view.layer.addSublayer(bottomRightLayer)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        bottomLeftLayer.emitterPosition = .init(x: -20, y: view.bounds.height + 20)
        bottomRightLayer.emitterPosition = .init(x: view.bounds.maxX + 20, y: view.bounds.height + 20)
        bottomLeftLayer.frame = view.bounds
        bottomRightLayer.frame = view.bounds

        bottomLeftLayer.setBehaviors([
            horizontalWaveBehavior,
            verticalWaveBehavior,
            dragBehavior,
            attractorBehavior(for: bottomLeftLayer, in: .bottomLeft),
        ])
        bottomRightLayer.setBehaviors([
            horizontalWaveBehavior,
            verticalWaveBehavior,
            dragBehavior,
            attractorBehavior(for: bottomRightLayer, in: .bottomRight),
        ])

        if !isEmitterLayerConfigured {
            setupAnimations(for: bottomLeftLayer)
            setupAnimations(for: bottomRightLayer)
            isEmitterLayerConfigured = true
        }
    }

    private func setupAnimations(for layer: CAEmitterLayer) {
        let stiffnessAnimation = CAKeyframeAnimation()
        stiffnessAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        stiffnessAnimation.duration = 3
        stiffnessAnimation.keyTimes = [0, 0.4]
        stiffnessAnimation.values = [340, 5]
        layer.add(stiffnessAnimation, forKey: "emitterBehaviors.attractor.stiffness")

        let birthRateAnimation = CABasicAnimation()
        birthRateAnimation.duration = 1
        birthRateAnimation.fromValue = 1
        birthRateAnimation.toValue = 0
        layer.add(birthRateAnimation, forKey: "birthRate")

        let gravityAnimation = CAKeyframeAnimation()
        gravityAnimation.duration = 6
        gravityAnimation.keyTimes = [0.05, 0.1, 0.5, 1]
        gravityAnimation.values = [0, 100, 2000, 4000]

        layer.emitterCells?.forEach { cell in
            layer.add(gravityAnimation, forKey: "emitterCells.\(cell.name!).yAcceleration")
        }
    }
}

extension ConfettiViewController {

    private func makeConfettiLayer() -> CAEmitterLayer {
        let emitterLayer = CAEmitterLayer()
        emitterLayer.birthRate = 0
        emitterLayer.emitterCells = confettiCells
        emitterLayer.emitterSize = CGSize(width: 120, height: 120)
        emitterLayer.emitterShape = .sphere
        emitterLayer.beginTime = CACurrentMediaTime()
        return emitterLayer
    }
}
