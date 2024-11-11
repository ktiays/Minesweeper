//
//  Created by ktiays on 2024/11/11.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import UIKit
import SwiftUI

func - (_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
    .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

extension CGPoint {
    
    var length: CGFloat {
        sqrt(x * x + y * y)
    }
}

final class BoardViewController: UIViewController {

    private struct LayoutCache {
        var cellLength: CGFloat = 0
        var contentRect: CGRect = .zero
    }

    let minefield: Minefield
    var spacing: CGFloat = 4 {
        didSet {
            view.setNeedsLayout()
        }
    }

    private var pieceLayers: [Int: CALayer] = [:]
    private var gridLayers: [Int: CALayer] = [:]

    private var layoutCache: LayoutCache = .init()
    private lazy var isPressedTransform: CATransform3D = CATransform3DMakeScale(0.9, 0.9, 1)

    init(minefield: Minefield) {
        self.minefield = minefield
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        for i in 0..<minefield.count {
            let layer = CALayer()
            layer.delegate = self
            layer.allowsEdgeAntialiasing = true
            view.layer.addSublayer(layer)
            pieceLayers[i] = layer
        }

        minefield.clearMine(at: .init(x: 0, y: 0))
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

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        updateLayoutCache()

        let width = minefield.width
        let height = minefield.height

        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let layer = pieceLayers[index]!
                let frame = frame(for: .init(x: x , y: y))
                
                // Reset the transform to get the correct frame.
                let transform = layer.transform
                layer.transform = CATransform3DIdentity
                layer.frame = rectInContentBounds(frame)
                layer.transform = transform

                let imageCache = ImageManager.shared.cache
                layer.contents = imageCache.unrevealed
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
    
    private func frame(for position: Minefield.Position) -> CGRect {
        let length = layoutCache.cellLength
        return .init(
            x: CGFloat(position.x) * (length + spacing) + spacing,
            y: CGFloat(position.y) * (length + spacing) + spacing,
            width: length,
            height: length
        )
    }

    // MARK: Touch Handling

    private final class DragState {

        enum State {
            case possible
            case began
            case changed
            case cancelled
            case ended
        }

        final class Context {
            var location: CGPoint = .zero
            var position: Minefield.Position?
            var layer: CALayer?
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
        guard let touch = touches.first else {
            return
        }

        let state = DragState(touch: touch)
        dragStates[touch] = state
        state.state = .began
        dragGestureDidChange(state)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        if let state = dragStates[touch] {
            state.state = .changed
            dragGestureDidChange(state)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        if let state = dragStates[touch] {
            state.state = .ended
            dragStates.removeValue(forKey: touch)
            dragGestureDidChange(state)
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
            let actualRect = frame(for: position)
            if actualRect.contains(location) {
                context.position = position
                let index = y * minefield.width + x
                let layer = pieceLayers[index]!
                context.layer = layer
                fallthrough
            }
        case .changed:
            guard let position = context.position,
                  let layer = context.layer
            else {
                return
            }
            
            let length = layoutCache.cellLength
            let translation = state.translation
            if translation.length > length * 2 {
                layer.transform = CATransform3DIdentity
            } else {
                layer.transform = isPressedTransform
            }
        case .cancelled, .ended:
            guard let layer = context.layer else {
                return
            }
            
            layer.transform = CATransform3DIdentity
        default:
            break
        }
    }
}

// MARK: - CALayerDelegate

extension BoardViewController: CALayerDelegate {
    
    func action(for layer: CALayer, forKey event: String) -> (any CAAction)? {
        let animation = CASpringAnimation()
        let spring = Spring(duration: 0.24)
        animation.damping = spring.damping
        animation.stiffness = spring.stiffness
        animation.mass = spring.mass
        return animation
    }
}
