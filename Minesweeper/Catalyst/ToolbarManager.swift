//
//  Created by ktiays on 2024/11/30.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#if targetEnvironment(macCatalyst)
import UIKit

@objc(MSPToolbarManager)
public final class ToolbarManager: NSObject {
    
    @objc(sharedManager)
    public static let shared = ToolbarManager()
    
    @objc
    public var leadingSpace: CGFloat = 0
    
    private var toolbarMap: [UIWindow: Toolbar] = [:]
    
    @objc(toolbarForWindow:)
    public func toolbar(for window: UIWindow) -> Toolbar {
        if let toolbar = toolbarMap[window] {
            return toolbar
        }
        
        let toolbar = Toolbar()
        toolbarMap[window] = toolbar
        return toolbar
    }
}
#endif
