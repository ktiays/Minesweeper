//
//  Created by ktiays on 2024/11/23.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI
import UIKit

final class BoardTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    let isPresenting: Bool

    private let spring: Spring = .smooth

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        spring.settlingDuration
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
            let toView = transitionContext.view(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        containerView.addSubview(toView)
        let containerWidth = containerView.bounds.width
        toView.frame = containerView.bounds.offsetBy(dx: isPresenting ? containerWidth : -containerWidth, dy: 0)
        
        UIView.animate(springDuration: spring.duration, bounce: spring.bounce) {
            toView.frame = containerView.bounds
            fromView.frame = containerView.bounds.offsetBy(dx: self.isPresenting ? -containerWidth : containerWidth, dy: 0)
        } completion: { _ in
            transitionContext.completeTransition(true)
        }
    }
}
