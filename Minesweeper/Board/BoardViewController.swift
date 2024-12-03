//
//  Created by ktiays on 2024/11/11.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import Combine
import SwiftUI
import UIKit
import With

public let null = NSNull()

public func withTransaction(@_implicitSelfCapture _ body: () -> Void, completion: @escaping () -> Void = {}) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    body()
    CATransaction.commit()
}

extension CALayer {

    func insertToFront(_ sublayer: CALayer) {
        insertSublayer(sublayer, at: UInt32(sublayers?.count ?? 0))
    }
}

private let animationIDKey = "AnimationID"
private let boardIndexKey = "BoardIndex"

final class BoardViewController: UIViewController, ObservableObject {

    public enum GameStatus {
        case idle
        case playing
        case win
        case lose
    }

    private struct LayoutCache {
        var cellLength: CGFloat = 0
        var contentRect: CGRect = .zero
    }

    private final class PieceState {
        var isPressed: Bool = false
        var isMenuActive: Bool = false
        var offset: CGPoint = .zero
        var isExplodedAnimating: Bool = false
        var candidateFlag: Minefield.Flag?
    }

    @MainActor
    private final class OverlayLayer {

        private let imageCache = ImageManager.shared.cache

        private(set) lazy var bombLayer: CALayer = {
            let layer = CALayer()
            layer.allowsEdgeAntialiasing = true
            layer.contents = imageCache.bomb
            return layer
        }()

        private(set) lazy var flagContainerLayer: FlagContainerLayer = {
            let layer = FlagContainerLayer()
            layer.allowsEdgeAntialiasing = true
            return layer
        }()
    }

    private enum ArcDirection {
        case top
        case bottom
    }

    private(set) var minefield: Minefield
    var spacingRatio: CGFloat = 0.1 {
        didSet {
            view.setNeedsLayout()
        }
    }

    @Published
    private(set) var gameStatus: GameStatus = .idle
    
    @Published
    private(set) var remainingMines: Int = 0

    #if targetEnvironment(macCatalyst)
    private let isSupportedDragInteraction: Bool = false
    #else
    private let isSupportedDragInteraction: Bool = true
    #endif

    private var pieceLayers: [Int: CALayer] = [:]
    private var gridLayers: [Int: CALayer] = [:]
    private var pieceStates: [Int: PieceState] = [:]
    private var overlayLayers: [Int: OverlayLayer] = [:]

    private var flagMenus: [Int: (LayerAnimatable, LayerAnimatable)] = [:]
    private var isPositionAnimationEnabled: Bool = false
    private var isGameOver: Bool {
        gameStatus == .win || gameStatus == .lose
    }

    private typealias AnimationID = UInt64

    private lazy var pathSpring: Spring = .init(duration: 0.24)
    private var animationCompletions: [AnimationID: () -> Void] = [:]

    private var layoutCache: LayoutCache = .init()
    private lazy var isPressedTransform: CATransform3D = CATransform3DMakeScale(0.9, 0.9, 1)
    
    private lazy var lightFeedback: UIImpactFeedbackGenerator = .init(style: .light)
    private lazy var rigidFeedback: UIImpactFeedbackGenerator = .init(style: .rigid)
    private lazy var notificationFeedback: UINotificationFeedbackGenerator = .init()
    
    @Incrementable
    private var animationID: AnimationID = 0
    private lazy var topLayerPathRadiusKey = CustomAnimatablePropertyKey(identifier: "topLayerPathRadius") { [weak self] radius, layer in
        let path = self?.arcPath(direction: .top, rect: layer.bounds, radius: radius)
        guard let shapeLayer = layer as? CAShapeLayer else {
            return
        }
        shapeLayer.path = path

        if let symbolLayer = shapeLayer.sublayers?.first {
            let height = shapeLayer.lineWidth
            let bounds = layer.bounds
            symbolLayer.frame = .init(
                x: (bounds.width - height) / 2,
                y: (bounds.height / 2 - radius) - height / 2,
                width: height,
                height: height
            )
        }
    }
    private lazy var bottomLayerPathRadiusKey = CustomAnimatablePropertyKey(identifier: "bottomLayerPathRadius") { [weak self] radius, layer in
        let path = self?.arcPath(direction: .bottom, rect: layer.bounds, radius: radius)
        guard let shapeLayer = layer as? CAShapeLayer else {
            return
        }
        shapeLayer.path = path

        if let symbolLayer = shapeLayer.sublayers?.first {
            let height = shapeLayer.lineWidth
            let bounds = layer.bounds
            symbolLayer.frame = .init(
                x: (bounds.width - height) / 2,
                y: (bounds.height / 2 + radius) - height / 2,
                width: height,
                height: height
            )
        }
    }

    private let normalLineWidthFactor: CGFloat = 0.15
    private let highlightedLineWidthFactor: CGFloat = 0.36

    init(minefield: Minefield) {
        self.minefield = minefield
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lightFeedback.prepare()
        rigidFeedback.prepare()
        notificationFeedback.prepare()
        view.backgroundColor = .clear

        if let secondaryClickGestureClass = NSClassFromString("_UISecondaryClickDriverGestureRecognizer") as? UIGestureRecognizer.Type {
            let gesture = secondaryClickGestureClass.init(target: self, action: #selector(handleSecondaryClick(_:)))
            view.addGestureRecognizer(gesture)
        } else {
            logger.error("Failed to create secondary click gesture recognizer")
        }
        
        reset(with: minefield)
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

        let spacing = length * spacingRatio
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
    
    func reset(with minefield: Minefield) {
        self.minefield = minefield
        remainingMines = minefield.numberOfMines
        
        if let sublayers = view.layer.sublayers {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }
        pieceLayers.removeAll()
        pieceStates.removeAll()
        gridLayers.removeAll()
        overlayLayers.removeAll()
        flagMenus.removeAll()
        animationCompletions.removeAll()
        isPositionAnimationEnabled = false
        
        for i in 0..<minefield.count {
            let layer = CALayer()
            layer.delegate = self
            layer.allowsEdgeAntialiasing = true
            layer.masksToBounds = true
            layer.cornerCurve = .continuous
            layer.setValue(i, forKey: boardIndexKey)
            view.layer.addSublayer(layer)
            pieceLayers[i] = layer
        }
        
        gameStatus = .idle
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
                    if minefield.isExploded && location.hasMine {
                        layer.contents = imageCache.exploded
                    } else {
                        layer.contents = imageCache.unrevealed
                    }
                }

                if let overlay = overlayLayers[index] {
                    let sublayerFrame = CGRect(origin: .zero, size: frame.size)
                    if minefield.isExploded && location.hasMine {
                        overlay.bombLayer.frame = sublayerFrame.scaleBy(0.7)
                    }
                    overlay.flagContainerLayer.frame = sublayerFrame
                }
            }
        }

        for (index, menu) in flagMenus {
            guard let state = pieceStates[index] else {
                continue
            }
            if !state.isMenuActive && !menu.0.isAnimating && !menu.1.isAnimating {
                continue
            }

            let cellFrame = self.rectInContentBounds(self.frame(at: index))
            let padding: CGFloat = cellFrame.width * 0.2
            let frame = cellFrame.insetBy(dx: -padding, dy: -padding)
            let foregroundColor = UIColor.systemOrange.cgColor

            [(menu.0, ArcDirection.top), (menu.1, ArcDirection.bottom)].forEach {
                guard let layer = $0.0.layer as? CAShapeLayer else {
                    return
                }
                layer.strokeColor = foregroundColor
                layer.frame = frame
            }
        }
    }

    private func cellLength(for size: CGSize) -> CGFloat {
        let width = minefield.width
        let height = minefield.height

        let widthSpecified = size.width / (CGFloat(width - 1) * spacingRatio + CGFloat(width))
        let heightSpecified = size.height / (CGFloat(height - 1) * spacingRatio + CGFloat(height))
        let length = if size.width / size.height > CGFloat(width) / CGFloat(height) {
            heightSpecified
        } else {
            widthSpecified
        }
        return min(length, 60)
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
        let spacing = layoutCache.cellLength * spacingRatio
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
        let spacing = length * spacingRatio
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
                  let pieceState = context.pieceState,
                  let position = context.position
            else {
                return
            }

            let index = context.index
            if index == NSNotFound {
                return
            }
            
            var needsFeedback: Bool = false

            let translation = state.translation
            let length = layoutCache.cellLength / 2
            let isCleared = minefield.location(at: position).isCleared
            let canActivateMenu = !isCleared && translation.length > length && isSupportedDragInteraction
            if canActivateMenu && !isGameOver && !pieceState.isMenuActive {
                pieceState.isMenuActive = true
                needsFeedback = true

                if flagMenus[index] == nil {
                    func makeMenuAnimatable() -> LayerAnimatable {
                        let shapeLayer = CAShapeLayer()
                        shapeLayer.setValue(index, forKey: boardIndexKey)
                        shapeLayer.delegate = self
                        shapeLayer.allowsEdgeAntialiasing = true
                        shapeLayer.lineCap = .round
                        shapeLayer.lineJoin = .round

                        if let blurFilter = GaussianBlurFilter() {
                            shapeLayer.filters = [blurFilter.effect]
                        }

                        let animatable: LayerAnimatable = .init(shapeLayer)
                        animatable.update(value: 10, for: \.blurRadius)
                        return animatable
                    }

                    // Add the flag and maybe symbol to the menu.
                    let imageCache = ImageManager.shared.cache
                    let flagSymbolLayer = NonAnimatingLayer()
                    flagSymbolLayer.allowsEdgeAntialiasing = true
                    flagSymbolLayer.contents = imageCache.flag
                    let maybeSymbolLayer = NonAnimatingLayer()
                    maybeSymbolLayer.allowsEdgeAntialiasing = true
                    maybeSymbolLayer.contents = imageCache.maybe

                    let topAnimatable = makeMenuAnimatable()
                    topAnimatable.layer.addSublayer(maybeSymbolLayer)

                    let bottomAnimatable = makeMenuAnimatable()
                    bottomAnimatable.layer.addSublayer(flagSymbolLayer)

                    flagMenus[index] = (topAnimatable, bottomAnimatable)

                    // Make sure the frame of layer is correctly set.
                    view.setNeedsLayout()
                    view.layoutIfNeeded()

                    topAnimatable.update(value: topAnimatable.layer.bounds.height * normalLineWidthFactor, for: \.lineWidth)
                    bottomAnimatable.update(value: bottomAnimatable.layer.bounds.height * normalLineWidthFactor, for: \.lineWidth)
                }

                let (topAnimatable, bottomAnimatable) = flagMenus[index]!
                view.layer.insertToFront(topAnimatable.layer)
                view.layer.insertToFront(bottomAnimatable.layer)
                view.layer.insertToFront(layer)
                withLayerAnimation(pathSpring) {
                    topAnimatable.update(value: 0, for: \.blurRadius)
                    topAnimatable.update(value: topAnimatable.layer.bounds.height / 2, for: topLayerPathRadiusKey)
                    topAnimatable.update(value: 1, for: \.opacity)
                    bottomAnimatable.update(value: 0, for: \.blurRadius)
                    bottomAnimatable.update(value: bottomAnimatable.layer.bounds.height / 2, for: bottomLayerPathRadiusKey)
                    bottomAnimatable.update(value: 1, for: \.opacity)
                }
            }

            let previousCandidateFlag = pieceState.candidateFlag
            pieceState.candidateFlag = nil
            if pieceState.isMenuActive, let menu = flagMenus[index] {
                let point = state.locationInView
                let center = layer.position
                let dx = abs(point.x - center.x)
                let dy = point.y - center.y
                let halfAngle = atan2(dy, dx)

                var highlightedTop = false
                var highlightedBottom = false
                if canActivateMenu {
                    if halfAngle > 0 {
                        highlightedBottom = (.pi / 2 - halfAngle) <= (20 * .pi / 180)
                    } else {
                        highlightedTop = (.pi / 2 - abs(halfAngle)) <= (20 * .pi / 180)
                    }
                }
                if highlightedTop {
                    pieceState.candidateFlag = .maybe
                } else if highlightedBottom {
                    pieceState.candidateFlag = .flag
                }

                let (topAnimatable, bottomAnimatable) = menu
                withLayerAnimation(.init(response: 0.3, dampingRatio: 0.7)) {
                    topAnimatable.update(
                        value: bottomAnimatable.layer.bounds.height * (highlightedTop ? 0.65 : 0.5),
                        for: topLayerPathRadiusKey
                    )
                    topAnimatable.update(
                        value: (highlightedTop ? highlightedLineWidthFactor : normalLineWidthFactor) * topAnimatable.layer.bounds.height,
                        for: \.lineWidth
                    )
                    bottomAnimatable.update(
                        value: bottomAnimatable.layer.bounds.height * (highlightedBottom ? 0.65 : 0.5),
                        for: bottomLayerPathRadiusKey
                    )
                    bottomAnimatable.update(
                        value: (highlightedBottom ? highlightedLineWidthFactor : normalLineWidthFactor) * bottomAnimatable.layer.bounds.height,
                        for: \.lineWidth
                    )
                }
            }
            if let candidateFlag = pieceState.candidateFlag, candidateFlag != previousCandidateFlag {
                needsFeedback = true
            }
            
            if needsFeedback {
                rigidFeedback.impactOccurred(intensity: 0.9)
                rigidFeedback.prepare()
            }

            pieceState.offset = with {
                let range: CGFloat = 5
                let width = translation.x
                let height = translation.y
                let x = rubberBandOffset(abs(width), range: range)
                let y = rubberBandOffset(abs(height), range: range)
                return CGPoint(x: width < 0 ? -x : x, y: height < 0 ? -y : y)
            }
            layer.transform = isPressedTransform
        case .cancelled, .ended:
            guard let layer = context.layer,
                let pieceState = context.pieceState,
                let position = context.position
            else {
                return
            }

            let length = layoutCache.cellLength
            if state.translation.length < length && !pieceState.isMenuActive {
                handlePieceTap(layer: layer, at: position)
            }
            
            if let candidateFlag = pieceState.candidateFlag {
                let location = minefield.location(at: position)
                let currentFlag = location.flag
                let targetFlag: Minefield.Flag = if currentFlag == candidateFlag {
                    .none
                } else {
                    candidateFlag
                }
                changeFlag(targetFlag, at: position)
            }

            isPositionAnimationEnabled = true
            pieceState.isMenuActive = false
            if let (topLayer, bottomLayer) = flagMenus[context.index] {
                withLayerAnimation(pathSpring) {
                    topLayer.update(value: 10, for: \.blurRadius)
                    bottomLayer.update(value: 10, for: \.blurRadius)

                    topLayer.update(value: 0, for: topLayerPathRadiusKey)
                    bottomLayer.update(value: 0, for: bottomLayerPathRadiusKey)

                    topLayer.update(value: 0, for: \.opacity)
                    bottomLayer.update(value: 0, for: \.opacity)
                }
            }

            withTransaction {
                pieceState.isPressed = false
                pieceState.offset = .zero
                pieceState.candidateFlag = nil
                layer.transform = CATransform3DIdentity
            } completion: {
                self.isPositionAnimationEnabled = false
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
                270
            case .bottom:
                90
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
        var needsUpdate = false
        if location.isCleared {
            if location.numberOfMinesAround > 0 {
                if minefield.multiRelease(at: position) {
                    needsUpdate = true
                }
            }
        } else {
            minefield.clearMine(at: position)
            needsUpdate = true

            if gameStatus == .idle && minefield.isPlacedMines {
                gameStatus = .playing
            }
        }
        if !needsUpdate { return }

        updateMinesWithAnimation(anchor: position)

        if minefield.isExploded {
            explode(at: position)
            gameStatus = .lose
            return
        }

        if minefield.isCompleted {
            congratulations()
            gameStatus = .win
            return
        }
        
        lightFeedback.impactOccurred(intensity: 0.8)
        lightFeedback.prepare()
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
            gridLayer.allowsEdgeAntialiasing = true
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

        notificationFeedback.notificationOccurred(.success)
        notificationFeedback.prepare()

        confetti.view.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(confetti.view)
        NSLayoutConstraint.activate([
            confetti.view.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            confetti.view.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            confetti.view.topAnchor.constraint(equalTo: window.topAnchor),
            confetti.view.bottomAnchor.constraint(equalTo: window.bottomAnchor),
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            confetti.view.removeFromSuperview()
        }
    }

    private func explode(at anchor: Minefield.Position) {
        notificationFeedback.notificationOccurred(.error)
        notificationFeedback.prepare()
        
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

            let animationBeginTime = CACurrentMediaTime() + Double(norm) * 1.9
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
                let bombLayer = overlay.bombLayer
                bombLayer.opacity = 0
                layer.addSublayer(bombLayer)

                let opacityAnimation = layer.opacityAnimation(
                    .init(duration: 0.2),
                    from: .constant(0),
                    to: 1
                )
                var bombAnimations: [CAAnimation] = [opacityAnimation]

                if location.flag != .none {
                    let transformAnimation = bombLayer.transformAnimation(
                        .init(duration: 0.3),
                        from: .current,
                        to: CATransform3DConcat(
                            CATransform3DMakeScale(0.9, 0.9, 1),
                            CATransform3DMakeTranslation(
                                -0.06 * frame.width,
                                0.06 * frame.height,
                                0
                            )
                        )
                    )
                    bombAnimations.append(transformAnimation)

                    let flagLayer = overlay.flagContainerLayer
                    let flagAnimation = flagLayer.transformAnimation(
                        .init(duration: 0.3),
                        from: .current,
                        to: CATransform3DConcat(
                            CATransform3DMakeScale(0.7, 0.7, 1),
                            CATransform3DMakeTranslation(
                                0.27 * frame.width,
                                -0.27 * frame.height,
                                0
                            )
                        )
                    )
                    flagAnimation.beginTime = animationBeginTime
                    flagLayer.add(flagAnimation, forKey: nil)
                }

                let bombAnimation = bombLayer.groupAnimation(with: bombAnimations)
                bombAnimation.beginTime = animationBeginTime
                bombLayer.add(bombAnimation, forKey: nil)

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
                self.addCompletion(for: animationGroup) {
                    pieceState.isExplodedAnimating = false
                    layer.backgroundColor = nil
                }
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
        if isGameOver {
            return
        }
        
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

            guard let position = position(at: beganLocation) else {
                return
            }
            changeFlag(at: position)
        default:
            break
        }
    }

    private func changeFlag(_ flag: Minefield.Flag? = nil, at position: Minefield.Position) {
        let location = minefield.location(at: position)
        if location.isCleared {
            return
        }

        let index = position.y * minefield.width + position.x
        guard let layer = pieceLayers[index] else {
            return
        }

        let flagLayer = overlayLayer(at: index).flagContainerLayer
        if flagLayer.superlayer == nil {
            layer.addSublayer(flagLayer)
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }

        if let flag {
            minefield.changeFlag(to: flag, at: position)
            flagLayer.changeFlag(to: flag, with: flag == .maybe ? .top : .bottom)
        } else {
            let next = location.flag.next()
            minefield.changeFlag(to: next, at: position)
            flagLayer.changeFlag(to: next)
        }
        
        remainingMines = minefield.numberOfMines - minefield.numberOfFlagged
    }
}

// MARK: - CALayerDelegate

extension BoardViewController: CALayerDelegate {

    func action(for layer: CALayer, forKey event: String) -> (any CAAction)? {
        if minefield.isExploded {
            let index = layer.value(forKey: boardIndexKey) as! Int
            if let state = pieceStates[index], state.isExplodedAnimating {
                return null
            }
        }
        if layer is CAShapeLayer {
            return null
        }

        switch event {
        case "transform", "opacity":
            return springAnimation(.init(duration: 0.24))
        case "cornerRadius":
            return springAnimation(.init(duration: 0.2))
        case "position":
            if isPositionAnimationEnabled {
                return springAnimation(.init(duration: 0.2))
            }
            fallthrough
        default:
            return null
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
