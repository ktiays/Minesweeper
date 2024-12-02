//
//  Created by ktiays on 2024/12/2.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import Foundation

@objc(MSPMenuManager)
final class MenuManager: NSObject {
    
    @objc(sharedManager)
    static let shared = MenuManager()
    
    private var menuWindows: Set<MenuWindow> = .init()
    
    @objc(addMenu:)
    func addMenu(_ menuWindow: MenuWindow) {
        menuWindows.insert(menuWindow)
    }
    
    @objc(removeMenu:)
    func removeMenu(_ menuWindow: MenuWindow) {
        menuWindows.remove(menuWindow)
    }
}
