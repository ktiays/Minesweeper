//
//  Created by ktiays on 2024/11/23.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import SwiftUI

let isMacCatalyst = ProcessInfo.processInfo.isMacCatalystApp

extension EnvironmentValues {
    
    @Entry var isMacCatalyst: Bool = ProcessInfo.processInfo.isMacCatalystApp
}
