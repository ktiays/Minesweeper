//
//  Created by ktiays on 2024/12/1.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import UIKit

final class AlertPresentationController: UIPresentationController {
 
    override func presentationTransitionWillBegin() {
        guard let alertController = presentedViewController as? AlertViewController else {
            return
        }
        alertController.dimmingView.alpha = 0
        alertController.contentView.alpha = 0
        alertController.contentView.transform = .init(scaleX: 1.1, y: 1.1)
        containerView?.addSubview(alertController.view)
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if (!completed) {
            presentedViewController.view.removeFromSuperview()
        }
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        
        (presentedViewController as? AlertViewController)?.layout(in: containerView?.bounds ?? .zero)
    }
}
