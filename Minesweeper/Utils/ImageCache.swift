//
//  Created by ktiays on 2024/11/11.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI
import UIKit

@MainActor
final class ImageCache {

    private let colorScheme: ColorScheme
    private var gridCache: [Int: CGImage] = [:]

    private static let textColorMap: [Int: Color] = [
        1: .oneText,
        2: .twoText,
        3: .threeText,
        4: .fourText,
        5: .fiveText,
        6: .sixText,
        7: .sevenText,
        8: .eightText,
    ]

    private(set) lazy var unrevealed: CGImage = renderContent {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        .pieceTopLeading,
                        .pieceBottomTrailing,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    init(colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }

    func grid(for count: Int) -> CGImage {
        if let image = gridCache[count] {
            return image
        }

        let cgImage = renderContent {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke()
                    .shadow(color: .black.opacity(colorScheme == .light ? 0.7 : 1), radius: 4, x: 2, y: 2)
                RoundedRectangle(cornerRadius: 12)
                    .stroke()
                    .shadow(color: .white.opacity(colorScheme == .dark ? 0.4 : 1), radius: 3, x: -2, y: -2)

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Self.textColorMap[count, default: .primary])
                }
            }
            .mask {
                RoundedRectangle(cornerRadius: 12)
                    .padding(2)
            }
        }
        gridCache[count] = cgImage
        return cgImage
    }

    private func renderContent<Content>(@ViewBuilder _ content: () -> Content) -> CGImage where Content: View {
        let renderer = ImageRenderer(content: content())
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = .init(width: 60, height: 60)
        return renderer.cgImage!
    }
}
