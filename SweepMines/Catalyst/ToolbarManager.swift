//
//  Created by ktiays on 2024/11/30.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

#if targetEnvironment(macCatalyst)
import UIKit
import Combine

@objc(MSPToolbarManager)
public final class ToolbarManager: NSObject {
    
    @objc(sharedManager)
    public static let shared = ToolbarManager()
    
    @objc
    public static let defaultToolbarHeight: CGFloat = 52
    
    @objc
    public var leadingSpace: CGFloat = 0
    
    private var toolbarMap: [UIWindow: Toolbar] = [:]
    private var titleBarVisibilityMap: [UIWindow: Bool] = [:]
    private var cancellables: Set<AnyCancellable> = .init()
    
    public override init() {
        super.init()
        
        NotificationCenter.default.publisher(for: .MSPNSTitlebarContainerViewVisibilityDidChangeNotificationName)
            .sink { [weak self] notification in
                guard let uiWindow = notification.userInfo?["UIWindow"] as? UIWindow else {
                    return
                }
                guard let isVisible = notification.object as? Bool else {
                    return
                }
                self?.titleBarVisibilityMap[uiWindow] = isVisible
                UIView.animate(springDuration: 0.28) {
                    uiWindow.setNeedsLayout()
                    uiWindow.layoutIfNeeded()
                }
            }
            .store(in: &cancellables)
    }
    
    @objc(toolbarForWindow:)
    public func toolbar(for window: UIWindow) -> Toolbar {
        if let toolbar = toolbarMap[window] {
            return toolbar
        }
        
        let toolbar = Toolbar()
        toolbarMap[window] = toolbar
        return toolbar
    }
    
    @objc(isTitleBarVisibleForWindow:)
    public func isTitleBarVisible(for window: UIWindow) -> Bool {
        titleBarVisibilityMap[window] ?? true
    }
}
#endif
