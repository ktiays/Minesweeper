//
//  Created by ktiays on 2024/11/14.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import UIKit

final class SharedDisplayLink: NSObject {

    struct Context {
        /// The time interval between screen refresh updates.
        let duration: CFTimeInterval

        /// The time interval that represents when the last frame displayed.
        let timestamp: CFTimeInterval

        /// The time interval that represents when the next frame displays.
        let targetTimestamp: CFTimeInterval
    }

    final class Target {

        fileprivate var isPaused: Bool = false
        fileprivate let handler: (Context) -> Void

        deinit {
            invalidate()
        }

        fileprivate init(handler: @escaping (Context) -> Void) {
            self.handler = handler
        }

        @inlinable
        func invalidate() {
            isPaused = true
        }
    }

    static let shared = SharedDisplayLink()

    private var displayLink: CADisplayLink?
    fileprivate var targets: [Target] = []

    func add(_ update: @escaping (Context) -> Void) -> Target {
        let target = Target(handler: update)
        targets.append(target)
        if displayLink == nil {
            let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
            link.preferredFrameRateRange = .init(minimum: 80, maximum: 120, preferred: 120)
            link.add(to: .current, forMode: .common)
            displayLink = link
        }
        return target
    }

    @objc
    private func handleDisplayLink(_ displayLink: CADisplayLink) {
        let context = Context(
            duration: displayLink.duration,
            timestamp: displayLink.timestamp,
            targetTimestamp: displayLink.targetTimestamp
        )
        
        var removeIndices: [Int] = []
        for (index, target) in targets.enumerated() {
            guard !target.isPaused else {
                removeIndices.append(index)
                continue
            }
            target.handler(context)
        }
        for index in removeIndices.reversed() {
            targets.remove(at: index)
        }
        
        if targets.isEmpty {
            displayLink.invalidate()
            self.displayLink = nil
        }
    }
}
