//
//  Created by ktiays on 2024/12/2.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI

struct SingleButtonMenu: View {
    
    @State private var isButtonHover: Bool = false
    
    private let buttonContent: ButtonContent
    private let message: LocalizedStringResource
    private let action: () -> Void
    
    struct ButtonContent {
        let image: Image
        let text: LocalizedStringResource
    }
    
    init(buttonContent: ButtonContent, message: LocalizedStringResource, action: @escaping () -> Void) {
        self.buttonContent = buttonContent
        self.message = message
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                action()
            } label: {
                HStack {
                    buttonContent.image
                        .font(.system(size: 10, weight: .bold))
                    Text(buttonContent.text)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Spacer()
                }
                .foregroundStyle(.warningText)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .drawingGroup()
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .foregroundStyle(.warningText)
                        .opacity(isButtonHover ? 0.1 : 0)
                }
                .padding(4)
            }
            .buttonStyle(ScaledButtonStyle(scale: 0.95))
            .onHover { isHover in
                isButtonHover = isHover
            }
            
            Divider()

            Text(message)
                .foregroundStyle(.secondary)
                .font(.system(size: 13, design: .rounded))
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: 180)
        .background {
            Color.boardBackground
                .opacity(0.7)
        }
    }
}
