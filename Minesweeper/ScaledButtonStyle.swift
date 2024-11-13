//
//  Created by ktiays on 2024/11/13.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import SwiftUI

struct ScaledButtonStyle: ButtonStyle {
    
    let scale: CGFloat
    
    init(scale: CGFloat = 0.9) {
        self.scale = scale
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(duration: 0.24), value: configuration.isPressed)
    }
}
