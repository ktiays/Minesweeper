//
//  Created by ktiays on 2024/11/19.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import QuartzCore

class NonAnimatingLayer: CALayer {
    override func action(forKey event: String) -> (any CAAction)? {
        null
    }
}
