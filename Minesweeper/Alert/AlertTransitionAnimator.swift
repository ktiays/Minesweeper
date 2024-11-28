//
//  Created by ktiays on 2024/11/28.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import UIKit

final class AlertTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }
    
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0.24
    }
    
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        let alertController = if isPresenting {
            transitionContext.viewController(forKey: .to)
        } else {
            transitionContext.viewController(forKey: .from)
        }
        guard let alertController = alertController as? AlertViewController else {
            logger.error("The view controller must be an instance of AlertViewController.")
            transitionContext.completeTransition(false)
            return
        }
        
        let dimmingView = alertController.dimmingView
        let alertView = alertController.contentView
        
        if isPresenting {
            let containerView = transitionContext.containerView
            containerView.addSubview(dimmingView)
            containerView.addSubview(alertView)
            
            alertController.layout(in: containerView.bounds)
            dimmingView.alpha = 0
            alertView.alpha = 0
            alertView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
        UIView.animate(springDuration: 0.3) {
            if isPresenting {
                dimmingView.alpha = 0.5
                alertView.alpha = 1
                alertView.transform = .identity
            } else {
                dimmingView.alpha = 0
                alertView.alpha = 0
                alertView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
        } completion: {
            transitionContext.completeTransition($0)
        }
    }
}
