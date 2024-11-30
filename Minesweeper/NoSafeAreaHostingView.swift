//
//  Created by ktiays on 2024/11/29.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import SwiftUI

class NoSafeAreaHostingView<Content>: _UIHostingView<Content> where Content: View {
    
    override var safeAreaInsets: UIEdgeInsets {
        .zero
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }
}
