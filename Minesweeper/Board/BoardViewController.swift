//
//  Created by ktiays on 2024/11/11.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI
import UIKit
import SnapKit

func - (_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
    .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func * (_ lhs: CGPoint, _ rhs: CGFloat) -> CGPoint {
    .init(x: lhs.x * rhs, y: lhs.y * rhs)
}

func withTransaction(@_implicitSelfCapture _ body: () -> Void, completion: @escaping () -> Void = {}) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    body()
    CATransaction.commit()
}

extension CGPoint {

    var length: CGFloat {
        sqrt(x * x + y * y)
    }
}

extension CGRect {
    
    var center: CGPoint {
        .init(x: midX, y: midY)
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

extension CALayer {
    
    func insertToFront(_ sublayer: CALayer) {
        insertSublayer(sublayer, at: UInt32(sublayers?.count ?? 0))
    }
}

fileprivate let animationIDKey = "AnimationID"
fileprivate let inputRadiusKeyPath = "filters.gaussianBlur.inputRadius"

final class BoardViewController: UIViewController {

    private struct LayoutCache {
        var cellLength: CGFloat = 0
        var contentRect: CGRect = .zero
    }

    private final class PieceState {
        var isPressed: Bool = false
        var isMenuActive: Bool = false
        var offset: CGPoint = .zero
        var isAnimated: Bool = false
        var isCleared: Bool = false
    }

    private enum ArcDirection {
        case top
        case bottom
    }

    let minefield: Minefield
    var spacing: CGFloat = 4 {
        didSet {
            view.setNeedsLayout()
        }
    }

    private var pieceLayers: [Int: CALayer] = [:]
    private var gridLayers: [Int: CALayer] = [:]
    private var pieceStates: [Int: PieceState] = [:]

    private var flagMenus: [Int: (CAShapeLayer, CAShapeLayer)] = [:]
    private var menuArcPaths: [CALayer: CGPath] = [:]
    private var isPositionAnimationEnabled: Bool = false
    private var isExplodedAnimating: Bool = false
    private var isGameOver: Bool = false

    private typealias AnimationID = UInt64

    private var animationCompletions: [AnimationID: () -> Void] = [:]

    private var layoutCache: LayoutCache = .init()
    private lazy var isPressedTransform: CATransform3D = CATransform3DMakeScale(0.9, 0.9, 1)
    private lazy var feedback: UIImpactFeedbackGenerator = .init(style: .rigid)

    @Incrementable
    private var animationID: AnimationID = 0

    init(minefield: Minefield) {
        self.minefield = minefield
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        feedback.prepare()

        for i in 0..<minefield.count {
            let layer = CALayer()
            layer.delegate = self
            layer.allowsEdgeAntialiasing = true
            layer.masksToBounds = true
            layer.cornerCurve = .continuous
            view.layer.addSublayer(layer)
            pieceLayers[i] = layer
        }
    }
    
    private func forEachField(_ body: (Int, Int, Int) -> Void) {
        for y in 0..<minefield.height {
            for x in 0..<minefield.width {
                let index = y * minefield.width + x
                body(x, y, index)
            }
        }
    }

    private func updateLayoutCache() {
        let bounds = view.bounds

        let length = cellLength(for: bounds.size)
        let width = minefield.width
        let height = minefield.height

        let boardWidth = CGFloat(width) * length + spacing * CGFloat(width + 1)
        let boardHeight = CGFloat(height) * length + spacing * CGFloat(height + 1)

        let contentRect = CGRect(
            x: (bounds.width - boardWidth) / 2,
            y: (bounds.height - boardHeight) / 2,
            width: boardWidth,
            height: boardHeight
        )

        layoutCache = .init(cellLength: length, contentRect: contentRect)
    }

    private func rectInContentBounds(_ rect: CGRect) -> CGRect {
        let contentRect = layoutCache.contentRect
        return .init(
            x: rect.minX + contentRect.minX,
            y: rect.minY + contentRect.minY,
            width: rect.width,
            height: rect.height
        )
    }
    
    // MARK: - Layout

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        updateLayoutCache()

        let length = layoutCache.cellLength
        let radius = length * 0.2

        forEachField { x, y, index in
            let pieceState = pieceStates[index]
            let isMenuActive = pieceState?.isMenuActive ?? false
            let offset = pieceState?.offset ?? .zero
            let isCleared = pieceState?.isCleared ?? false
            let imageCache = ImageManager.shared.cache
            
            let frame = self.frame(at: .init(x: x, y: y))
            let cellFrame = self.rectInContentBounds(frame)
            
            if isCleared {
                let location = minefield.locationAt(x: x, y: y)
                let layer = gridLayers[index]!
                layer.contents = imageCache.grid(for: location.numberOfMinesAround)
                layer.frame = cellFrame
            } else {
                let layer = pieceLayers[index]!
                
                // Reset the transform to get the correct frame.
                let transform = layer.transform
                layer.transform = CATransform3DIdentity
                layer.frame = cellFrame.offsetBy(dx: offset.x, dy: offset.y)
                layer.cornerRadius = isMenuActive ? (length / 2) : radius
                layer.transform = transform
                layer.contents = imageCache.unrevealed
            }
        }

        for (index, menu) in flagMenus {
            guard let state = pieceStates[index] else {
                continue
            }

            let isMenuActive = state.isMenuActive
            
            let padding: CGFloat = 30
            let frame = self.rectInContentBounds(self.frame(at: index).insetBy(dx: -padding, dy: -padding))
            let foregroundColor = UIColor.systemOrange.cgColor

            func doActionForMenu(_ action: (CAShapeLayer, ArcDirection) -> Void) {
                [(menu.0, ArcDirection.top), (menu.1, ArcDirection.bottom)].forEach {
                    action($0.0, $0.1)
                }
            }

            doActionForMenu { layer, direction in
                layer.strokeColor = foregroundColor
                layer.lineWidth = 10
                layer.frame = frame
            }

            if !state.isAnimated {
                let pathAnimation = CAAnimation.spring(duration: 0.24)
                let blurAnimation = CAAnimation.spring(duration: 0.2)
                blurAnimation.keyPath = inputRadiusKeyPath
                
                doActionForMenu { layer, direction in
                    let beganPath = arcPath(direction: direction, rect: frame, radius: 0)
                    let endPath = arcPath(direction: direction, rect: frame, radius: 30)
                    let highlightedPath = arcPath(direction: direction, rect: frame, radius: 35)
                    
                    if isMenuActive {
                        pathAnimation.fromValue = beganPath
                        pathAnimation.toValue = endPath
                        blurAnimation.fromValue = 10
                        blurAnimation.toValue = 0
                    } else {
                        let presentation = layer.presentation()
                        pathAnimation.fromValue = presentation?.path
                        pathAnimation.toValue = beganPath
                        blurAnimation.fromValue = presentation?.value(forKeyPath: inputRadiusKeyPath)
                        blurAnimation.toValue = 10
                        addCompletion(for: pathAnimation) { [self] in
                            layer.removeFromSuperlayer()
                            if let pieceLayer = self.pieceLayers[index] {
                                self.view.layer.insertSublayer(pieceLayer, at: 0)
                            }
                            self.flagMenus.removeValue(forKey: index)
                        }
                    }
                    layer.add(pathAnimation, forKey: "path")
                    layer.add(blurAnimation, forKey: "blurFilter")
                }
                state.isAnimated = true
            }
        }
    }

    private func cellLength(for size: CGSize) -> CGFloat {
        let width = minefield.width
        let height = minefield.height

        let widthSpecified = (size.width - spacing * CGFloat(width + 1)) / CGFloat(width)
        let heightSpecified = (size.height - spacing * CGFloat(height + 1)) / CGFloat(height)
        return if size.width / size.height > CGFloat(width) / CGFloat(height) {
            heightSpecified
        } else {
            widthSpecified
        }
    }

    private func frame(at index: Int) -> CGRect {
        let x = index % minefield.width
        let y = index / minefield.width
        return frame(at: .init(x: x, y: y))
    }

    private func frame(at position: Minefield.Position) -> CGRect {
        let length = layoutCache.cellLength
        return .init(
            x: CGFloat(position.x) * (length + spacing) + spacing,
            y: CGFloat(position.y) * (length + spacing) + spacing,
            width: length,
            height: length
        )
    }

    private func state(at position: Minefield.Position) -> PieceState {
        state(at: position.y * minefield.width + position.x)
    }

    private func state(at index: Int) -> PieceState {
        if let state = pieceStates[index] {
            return state
        }

        let state = PieceState()
        pieceStates[index] = state
        return state
    }
    
    private func activeLayer(at position: Minefield.Position) -> CALayer {
        let state = state(at: position)
        let index = position.y * minefield.width + position.x
        return if state.isCleared {
            gridLayers[index]!
        } else {
            pieceLayers[index]!
        }
    }

    // MARK: - Touch Handling

    private final class DragState {

        enum State {
            case possible
            case began
            case changed
            case cancelled
            case ended
        }

        final class Context {
            var index: Int = NSNotFound
            var location: CGPoint = .zero
            var position: Minefield.Position?
            var layer: CALayer?
            var pieceState: PieceState?
        }

        private let touch: UITouch
        private let beganLocation: CGPoint

        var state: State = .possible
        let context: Context = .init()

        var locationInView: CGPoint {
            touch.location(in: touch.view)
        }

        var translation: CGPoint {
            locationInView - beganLocation
        }

        init(touch: UITouch) {
            self.touch = touch
            self.beganLocation = touch.location(in: touch.view)
        }
    }

    private typealias DragContext = DragState.Context

    private var dragStates: [UITouch: DragState] = [:]

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isExplodedAnimating {
            return
        }
        for touch in touches {
            let state = DragState(touch: touch)
            dragStates[touch] = state
            state.state = .began
            dragGestureDidChange(state)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let state = dragStates[touch] {
                state.state = .changed
                dragGestureDidChange(state)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let state = dragStates[touch] {
                state.state = .ended
                dragStates.removeValue(forKey: touch)
                dragGestureDidChange(state)
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        if let state = dragStates[touch] {
            state.state = .cancelled
            dragStates.removeValue(forKey: touch)
            dragGestureDidChange(state)
        }
    }
    
    // MARK: Drag

    private func dragGestureDidChange(_ state: DragState) {
        func convertPointToContent(_ point: CGPoint) -> CGPoint {
            let contentRect = layoutCache.contentRect
            return .init(
                x: point.x - contentRect.minX,
                y: point.y - contentRect.minY
            )
        }

        let context = state.context

        switch state.state {
        case .began:
            let location = convertPointToContent(state.locationInView)
            context.location = location
            let x = Int(location.x / (layoutCache.cellLength + spacing))
            let y = Int(location.y / (layoutCache.cellLength + spacing))
            if x < 0 || x >= minefield.width || y < 0 || y >= minefield.height {
                return
            }
            let position = Minefield.Position(x: x, y: y)
            // Checks if the location hits on the spacing.
            let actualRect = frame(at: position)
            if actualRect.contains(location) {
                context.position = position
                let index = y * minefield.width + x
                let layer = pieceLayers[index]!
                context.index = index
                context.layer = layer
                let pieceState = self.state(at: position)
                pieceState.isPressed = true
                context.pieceState = pieceState
                fallthrough
            }
        case .changed:
            guard let layer = context.layer,
                  let pieceState = context.pieceState
            else {
                return
            }

            let index = context.index
            if index == NSNotFound {
                return
            }

            let translation = state.translation
            let length = layoutCache.cellLength
            if translation.length > length {
                if flagMenus[index] == nil {
                    pieceState.isMenuActive = true
                    pieceState.isAnimated = false

                    func makeMenuLayer() -> CAShapeLayer {
                        let shapeLayer = CAShapeLayer()
                        shapeLayer.delegate = self
                        shapeLayer.allowsEdgeAntialiasing = true
                        shapeLayer.lineCap = .round
                        shapeLayer.lineJoin = .round
                        
                        if var blurFilter = GaussianBlurFilter() {
                            blurFilter.inputRadius = 10
                            shapeLayer.filters = [blurFilter.effect]
                        }
                        view.layer.insertToFront(shapeLayer)
                        return shapeLayer
                    }

                    let topLayer = makeMenuLayer()
                    let bottomLayer = makeMenuLayer()
                    view.layer.insertToFront(layer)
                    flagMenus[index] = (topLayer, bottomLayer)
                }
            }

            func calculatePieceOffset() -> CGPoint {
                let range: CGFloat = 5
                let width = translation.x
                let height = translation.y
                let x = rubberBandOffset(abs(width), range: range)
                let y = rubberBandOffset(abs(height), range: range)
                return .init(x: width < 0 ? -x : x, y: height < 0 ? -y : y)
            }
            pieceState.offset = calculatePieceOffset()
            layer.transform = isPressedTransform
        case .cancelled, .ended:
            guard let layer = context.layer,
                  let pieceState = context.pieceState,
                  let position = context.position
            else {
                return
            }
            
            isPositionAnimationEnabled = true
            withTransaction {
                pieceState.isPressed = false
                pieceState.isMenuActive = false
                pieceState.isAnimated = false
                pieceState.offset = .zero
                layer.transform = CATransform3DIdentity
            } completion: {
                self.isPositionAnimationEnabled = false
            }
            
            let length = layoutCache.cellLength
            if state.translation.length < length && !pieceState.isMenuActive {
                handlePieceTap(layer: layer, at: position)
            }
        default:
            break
        }

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func rubberBandOffset(_ offset: CGFloat, range: CGFloat) -> CGFloat {
        let coefficient: CGFloat = 0.03
        // Check if offset and range are positive.
        if offset < 0 || range <= 0 {
            return 0
        }
        return (1 - (1 / (offset / range * coefficient + 1))) * range
    }

    private func arcPath(direction: ArcDirection, rect: CGRect, radius: CGFloat) -> CGPath {
        let length = rect.height
        let center = CGPoint(x: length / 2, y: length / 2)
        let path = CGMutablePath()
        let targetAngle: Double =
            switch direction {
            case .top:
                90
            case .bottom:
                270
            }
        let angle: Double = 40
        path.addArc(
            center: center,
            radius: radius,
            startAngle: Angle.degrees(targetAngle - angle / 2).radians,
            endAngle: Angle.degrees(targetAngle + angle / 2).radians,
            clockwise: false
        )
        return path
    }

    private func addCompletion(for animation: CAAnimation, completion: @escaping () -> Void) {
        animation.delegate = self
        let id = animationID
        animation.setValue(id, forKey: animationIDKey)
        animationCompletions[id] = completion
    }
    
    // MARK: Tap
    
    private func handlePieceTap(layer: CALayer, at position: Minefield.Position) {
        if isGameOver { return }
        
        let location = minefield.location(at: position)
        if location.isCleared {
            if location.numberOfMinesAround > 0 {
                minefield.multiRelease(at: position)
            }
            return
        } else {
            minefield.clearMine(at: position)
        }
        
        if minefield.isExploded {
            explode(at: position)
            isGameOver = true
            return
        }
        
        if minefield.isCompleted {
            congratulations()
            isGameOver = true
            return
        }
        
        updateMinesWithAnimation(anchor: position)
    }
    
    private func updateMinesWithAnimation(anchor: Minefield.Position) {
        let anchorFrame = frame(at: anchor)
        forEachField { x, y, index in
            let position = Minefield.Position(x: x, y: y)
            let pieceState = state(at: position)
            
            let location = minefield.location(at: position)
            if !pieceState.isCleared && location.isCleared {
                guard let layer = pieceLayers[index] else {
                    assertionFailure()
                    return
                }
                
                let frame = frame(at: position)
                let distance = (frame.center - anchorFrame.center).length
                
                let presentation = layer.presentation()
                
                let opacityAnimation = CAAnimation.spring(dampingRatio: 0.7)
                opacityAnimation.keyPath = "opacity"
                opacityAnimation.fromValue = presentation?.opacity
                opacityAnimation.toValue = 0
                
                let scaleAnimation = CAAnimation.spring(dampingRatio: 0.7)
                scaleAnimation.keyPath = "transform"
                scaleAnimation.fromValue = presentation?.transform
                scaleAnimation.toValue = CATransform3DMakeScale(0, 0, 1)
                
                let animation = CAAnimationGroup()
                animation.animations = [opacityAnimation, scaleAnimation]
                animation.isRemovedOnCompletion = false
                animation.fillMode = .forwards
                animation.beginTime = CACurrentMediaTime() + Double(distance) * 0.002
                
                addCompletion(for: animation) {
                    layer.removeFromSuperlayer()
                    self.pieceLayers.removeValue(forKey: index)
                }
                layer.add(animation, forKey: nil)
                
                let gridLayer = CALayer()
                view.layer.insertSublayer(gridLayer, below: layer)
                gridLayers[index] = gridLayer
                
                pieceState.isCleared = true
            }
        }
    }
    
    private func congratulations() {
        let confetti = ConfettiViewController()
        guard let window = view.window else {
            assertionFailure()
            return
        }

        feedback.impactOccurred()
        feedback.prepare()

        window.addSubview(confetti.view)
        confetti.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            confetti.view.removeFromSuperview()
        }
    }
    
    private func explode(at anchor: Minefield.Position) {
        let anchorFrame = frame(at: anchor)
        forEachField { x, y, index in
            let position = Minefield.Position(x: x, y: y)
            let pieceState = state(at: position)
            if pieceState.isCleared {
                return
            }
            
            let layer = activeLayer(at: position)
            let location = minefield.location(at: position)
            let frame = self.frame(at: position)
            let distance = frame.center - anchorFrame.center
            let norm = distance.length
            
            let animationBeginTime = CACurrentMediaTime() + Double(norm) * 0.0014
            
            layer.removeAllAnimations()
            
            let theta = atan2(distance.y, distance.x)
            let hypotenuse = norm * 0.04
            let offset: CGPoint = .init(
                x: hypotenuse * cos(theta),
                y: hypotenuse * sin(theta)
            )
            
            let enlargeAnimation = CAAnimation.spring(dampingRatio: 0.2)
            enlargeAnimation.keyPath = "transform"
            enlargeAnimation.fromValue = layer.presentation()?.transform
            enlargeAnimation.toValue = CATransform3DConcat(
                CATransform3DMakeScale(1.15, 1.15, 1),
                CATransform3DMakeTranslation(offset.x, offset.y, 0)
            )
            enlargeAnimation.beginTime = animationBeginTime
            addCompletion(for: enlargeAnimation) {
                let restoreAnimation = CAAnimation.spring(response: 0.5, dampingRatio: 0.48)
                restoreAnimation.keyPath = "transform"
                restoreAnimation.fromValue = layer.presentation()?.transform
                restoreAnimation.toValue = CATransform3DIdentity
                restoreAnimation.duration = restoreAnimation.value(forKey: "settlingDuration") as! TimeInterval
                self.addCompletion(for: restoreAnimation) {
                    self.isExplodedAnimating = false
                }
                layer.add(restoreAnimation, forKey: nil)
            }
            layer.add(enlargeAnimation, forKey: nil)
            isExplodedAnimating = true
        }
    }
}
 
// MARK: - CALayerDelegate

private func makeSpringAnimationWithSpring(_ spring: Spring) -> CASpringAnimation {
    let animation = CASpringAnimation()
    animation.damping = spring.damping
    animation.stiffness = spring.stiffness
    animation.mass = spring.mass
    animation.preferredFrameRateRange = .init(minimum: 80, maximum: 120, preferred: 120)
    animation.fillMode = .forwards
    animation.isRemovedOnCompletion = false
    animation.setValue(spring.settlingDuration, forKey: "settlingDuration")
    return animation
}

extension CAAnimation {

    static func spring(duration: TimeInterval = 0.5, bounce: Double = 0) -> CASpringAnimation {
        let spring = Spring(duration: duration, bounce: bounce)
        return makeSpringAnimationWithSpring(spring)
    }

    static func spring(mass: Double, stiffness: Double, damping: Double) -> CASpringAnimation {
        let spring = Spring(mass: mass, stiffness: stiffness, damping: damping)
        return makeSpringAnimationWithSpring(spring)
    }
    
    static func spring(response: Double = 0.5, dampingRatio: Double = 0.825) -> CASpringAnimation {
        let spring = Spring(response: response, dampingRatio: dampingRatio)
        return makeSpringAnimationWithSpring(spring)
    }
}

extension BoardViewController: CALayerDelegate {

    func action(for layer: CALayer, forKey event: String) -> (any CAAction)? {
        switch event {
        case "transform", "opacity":
            return CAAnimation.spring(duration: 0.24)
        case "cornerRadius", inputRadiusKeyPath:
            return CAAnimation.spring(duration: 0.2)
        case "position":
            if isPositionAnimationEnabled {
                return CAAnimation.spring(duration: 0.2)
            }
            fallthrough
        default:
            return NSNull()
        }
    }
}

// MARK: - CAAnimationDelegate

extension BoardViewController: CAAnimationDelegate {

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let id = anim.value(forKey: animationIDKey) as? AnimationID,
              let completion = animationCompletions[id]
        else {
            return
        }

        completion()
        animationCompletions.removeValue(forKey: id)
    }
}
