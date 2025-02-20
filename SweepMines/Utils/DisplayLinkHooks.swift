//
//  Created by Cyandev on 2024/10/26.
//  Copyright (c) 2024 Cyandev. All rights reserved.
// 

import QuartzCore
import ObjectiveC

@MainActor
enum DisplayLinkHooks {
    
    private static var isInstalled: Bool = false
    
    static func install() {
        guard !isInstalled else { return }
        
        let method = class_getInstanceMethod(
            CADisplayLink.self,
            #selector(CADisplayLink.add(to:forMode:))
        )!
        let origFunc = unsafeBitCast(
            method_getImplementation(method),
            to: (@convention(c) (CADisplayLink, Selector?, RunLoop, RunLoop.Mode) -> Void).self
        )
        let newBlock: @convention(block) (CADisplayLink, RunLoop, RunLoop.Mode) -> Void = { this, rl, mode in
            this.preferredFrameRateRange = .init(minimum: 80, maximum: 120, preferred: 120)
            origFunc(this, nil, rl, mode)
        }
        method_setImplementation(method, imp_implementationWithBlock(newBlock))
    }
}
