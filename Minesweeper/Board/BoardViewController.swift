//
//  Created by ktiays on 2024/11/11.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SnapKit
import SwiftUI
import UIKit

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

extension CALayer {

    func insertToFront(_ sublayer: CALayer) {
        insertSublayer(sublayer, at: UInt32(sublayers?.count ?? 0))
    }
}

private let animationIDKey = "AnimationID"
private let inputRadiusKeyPath = "filters.gaussianBlur.inputRadius"

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
        var isExplodedAnimating: Bool = false
    }

    @MainActor
    private final class OverlayLayer {

        private let imageCache = ImageManager.shared.cache

        lazy var boomLayer: CALayer = {
            let layer = CALayer()
            layer.contents = imageCache.boom
            return layer
        }()
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
    private var overlayLayers: [Int: OverlayLayer] = [:]

    private var flagMenus: [Int: (CAShapeLayer, CAShapeLayer)] = [:]
    private var menuArcPaths: [CALayer: CGPath] = [:]
    private var isPositionAnimationEnabled: Bool = false
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

        if let secondaryClickGestureClass = NSClassFromString("_UISecondaryClickDriverGestureRecognizer") as? UIGestureRecognizer.Type {
            let gesture = secondaryClickGestureClass.init(target: self, action: #selector(handleSecondaryClick(_:)))
            view.addGestureRecognizer(gesture)
        } else {
            logger.error("Failed to create secondary click gesture recognizer")
        }

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
            let location = minefield.locationAt(x: x, y: y)
            let isMenuActive = pieceState?.isMenuActive ?? false
            let isExplodedAnimating = pieceState?.isExplodedAnimating ?? false
            let offset = pieceState?.offset ?? .zero
            let imageCache = ImageManager.shared.cache

            let frame = self.frame(at: .init(x: x, y: y))
            let cellFrame = self.rectInContentBounds(frame)

            if location.isCleared {
                let layer = gridLayers[index]!
                layer.contents = imageCache.grid(for: location.numberOfMinesAround)
                layer.frame = cellFrame
            } else {
                let layer = pieceLayers[index]!
                let frame = cellFrame.offsetBy(dx: offset.x, dy: offset.y)

                // Reset the transform to get the correct frame.
                let transform = layer.transform
                layer.transform = CATransform3DIdentity
                layer.frame = frame
                layer.cornerRadius = isMenuActive ? (length / 2) : radius
                layer.transform = transform
                if !isExplodedAnimating {
                    layer.contents = imageCache.unrevealed
                }

                if let overlay = overlayLayers[index] {
                    if minefield.isExploded && location.hasMine {
                        overlay.boomLayer.frame = .init(origin: .zero, size: frame.size).insetBy(dx: 6, dy: 6)
                    }
                }
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
                let pathCurve = Spring(duration: 0.24)
                let blurCurve = Spring(duration: 0.2)

                doActionForMenu { layer, direction in
                    let beganPath = arcPath(direction: direction, rect: frame, radius: 0)
                    let endPath = arcPath(direction: direction, rect: frame, radius: 30)
                    let highlightedPath = arcPath(direction: direction, rect: frame, radius: 35)

                    let pathAnimation: CASpringAnimation
                    let blurAnimation: CASpringAnimation
                    if isMenuActive {
                        pathAnimation = layer.pathAnimation(
                            pathCurve,
                            from: .constant(beganPath),
                            to: endPath
                        )
                        blurAnimation = layer.customKeyPathAnimation(
                            blurCurve,
                            keyPath: inputRadiusKeyPath,
                            from: .constant(10),
                            to: 0
                        )
                    } else {
                        pathAnimation = layer.pathAnimation(
                            pathCurve,
                            from: .current,
                            to: beganPath
                        )
                        blurAnimation = layer.customKeyPathAnimation(
                            blurCurve,
                            keyPath: inputRadiusKeyPath,
                            from: .current,
                            to: 10
                        )
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

    private func position(at point: CGPoint) -> Minefield.Position? {
        let contentRect = layoutCache.contentRect
        let location = CGPoint(
            x: point.x - contentRect.minX,
            y: point.y - contentRect.minY
        )
        let x = Int(location.x / (layoutCache.cellLength + spacing))
        let y = Int(location.y / (layoutCache.cellLength + spacing))
        if x < 0 || x >= minefield.width || y < 0 || y >= minefield.height {
            return nil
        }
        // Checks if the location hits on the spacing.
        let position = Minefield.Position(x: x, y: y)
        let actualRect = frame(at: position)
        if actualRect.contains(location) {
            return position
        }
        return nil
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
        let index = position.y * minefield.width + position.x
        let location = minefield.location(at: position)
        return if location.isCleared {
            gridLayers[index]!
        } else {
            pieceLayers[index]!
        }
    }

    private func overlayLayer(at index: Int) -> OverlayLayer {
        if let overlayLayer = overlayLayers[index] {
            return overlayLayer
        }

        let layer = OverlayLayer()
        overlayLayers[index] = layer
        return layer
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
        let context = state.context

        switch state.state {
        case .began:
            guard let position = position(at: state.locationInView) else {
                return
            }

            context.position = position
            let x = position.x
            let y = position.y
            let index = y * minefield.width + x
            context.index = index
            context.layer = activeLayer(at: position)
            let pieceState = self.state(at: position)
            pieceState.isPressed = true
            context.pieceState = pieceState
            fallthrough
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
            if translation.length > length && !isGameOver {
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
            return
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
        let contentDiagonal = layoutCache.contentRect.diagonal
        forEachField { x, y, index in
            let position = Minefield.Position(x: x, y: y)

            let location = minefield.location(at: position)
            // If the layer has already been created, there is no need to call this function.
            let isUncovered = gridLayers[index] != nil
            if !location.isCleared || isUncovered {
                return
            }

            guard let layer = pieceLayers[index] else {
                logger.error("Layer not found at \(position)")
                assertionFailure()
                return
            }

            let frame = frame(at: position)
            let distance = (frame.center - anchorFrame.center).length / contentDiagonal

            let curve = Spring(response: 0.5, dampingRatio: 0.7)
            let opacityAnimation = layer.opacityAnimation(curve, from: .current, to: 0)
            let scaleAnimation = layer.scaleAnimation(curve, from: .current, to: 0)
            let animation = layer.groupAnimation(with: [opacityAnimation, scaleAnimation])
            animation.beginTime = CACurrentMediaTime() + Double(distance) * 2

            addCompletion(for: animation) {
                layer.removeFromSuperlayer()
                self.pieceLayers.removeValue(forKey: index)
            }
            layer.add(animation, forKey: nil)

            let gridLayer = CALayer()
            view.layer.insertSublayer(gridLayer, below: layer)
            gridLayers[index] = gridLayer
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
        let contentDiagonal = layoutCache.contentRect.diagonal
        forEachField { x, y, index in
            let position = Minefield.Position(x: x, y: y)
            let location = minefield.location(at: position)
            if location.isCleared {
                return
            }
            let hasMine = location.hasMine

            guard let layer = pieceLayers[index] else {
                logger.error("Layer not found at \(position)")
                assertionFailure()
                return
            }
            let pieceState = state(at: index)
            let frame = self.frame(at: position)
            let distance = frame.center - anchorFrame.center
            let norm = distance.length / contentDiagonal

            let animationBeginTime = CACurrentMediaTime() + Double(norm) * 2.1
            let offset: CGPoint = distance * 0.05
            let imageCache = ImageManager.shared.cache

            layer.removeAllAnimations()
            
            let previousPhaseCurve = Spring(response: 0.5, dampingRatio: 0.2)
            
            let enlargeAnimation = layer.transformAnimation(
                previousPhaseCurve,
                from: .current,
                to: CATransform3DConcat(
                    CATransform3DMakeScale(1.15, 1.15, 1),
                    CATransform3DMakeTranslation(offset.x, offset.y, 0)
                )
            )

            var animations: [CAAnimation] = [enlargeAnimation]

            if hasMine {
                let overlay = overlayLayer(at: index)
                let boomLayer = overlay.boomLayer
                boomLayer.opacity = 0
                layer.addSublayer(boomLayer)

                let opacityAnimation = layer.opacityAnimation(
                    .init(duration: 0.2),
                    from: .constant(0),
                    to: 1
                )
                opacityAnimation.beginTime = animationBeginTime
                boomLayer.add(opacityAnimation, forKey: nil)

                let contentsAnimation = layer.contentsAnimation(
                    previousPhaseCurve,
                    from: .current,
                    to: imageCache.empty
                )
                animations.append(contentsAnimation)
                layer.backgroundColor = UIColor.systemRed.cgColor
            } else {
                let opacityAnimation = layer.opacityAnimation(
                    .init(duration: 0.2),
                    from: .current,
                    to: 0.2
                )
                animations.append(opacityAnimation)
            }

            let animationGroup = layer.groupAnimation(with: animations)
            animationGroup.beginTime = animationBeginTime
            addCompletion(for: animationGroup) {
                let laterPhaseCurve = Spring(response: 0.5, dampingRatio: 0.48)

                let restoreAnimation = layer.transformAnimation(
                    laterPhaseCurve,
                    from: .current,
                    to: CATransform3DIdentity
                )
                self.addCompletion(for: restoreAnimation) {
                    pieceState.isExplodedAnimating = false
                    layer.backgroundColor = nil
                }

                var animations: [CAAnimation] = [restoreAnimation]

                if hasMine {
                    let contentsAnimation = layer.contentsAnimation(
                        laterPhaseCurve,
                        from: .current,
                        to: imageCache.exploded
                    )
                    animations.append(contentsAnimation)
                }

                let animationGroup = layer.groupAnimation(with: animations)
                animationGroup.duration = restoreAnimation.settlingDuration
                layer.add(animationGroup, forKey: nil)
            }
            layer.add(animationGroup, forKey: nil)
            pieceState.isExplodedAnimating = true
        }
    }

    // MARK: Secondary Click

    private var secondaryClickBeganLocation: CGPoint?

    @objc
    private func handleSecondaryClick(_ sender: UIGestureRecognizer) {
        let location = sender.location(in: view)
        switch sender.state {
        case .began:
            secondaryClickBeganLocation = location
        case .ended, .cancelled:
            defer {
                secondaryClickBeganLocation = nil
            }
            guard let beganLocation = secondaryClickBeganLocation else {
                return
            }
            let distance = (location - beganLocation).length
            if distance > 10 {
                return
            }

            guard let position = position(at: location) else {
                return
            }

            if minefield.location(at: position).isCleared {
                return
            }

            let index = position.y * minefield.width + position.x
            guard let layer = pieceLayers[index] else {
                return
            }
        default:
            break
        }
    }

    private func changeFlag(_ flag: Minefield.Flag, at position: Minefield.Position) {

    }
}

// MARK: - CALayerDelegate

extension BoardViewController: CALayerDelegate {

    func action(for layer: CALayer, forKey event: String) -> (any CAAction)? {
        switch event {
        case "transform", "opacity":
            return springAnimation(.init(duration: 0.24))
        case "cornerRadius", inputRadiusKeyPath:
            return springAnimation(.init(duration: 0.2))
        case "position":
            if isPositionAnimationEnabled {
                return springAnimation(.init(duration: 0.2))
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
