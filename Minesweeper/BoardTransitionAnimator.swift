//
//  Created by ktiays on 2024/11/23.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import UIKit

final class BoardTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let isPresenting: Bool
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }
    
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        1
    }
    
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        
    }
}
