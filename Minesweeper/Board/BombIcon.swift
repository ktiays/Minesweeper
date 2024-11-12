//
//  Created by ktiays on 2024/11/12.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import SwiftUI
import With

struct BombIcon: View {

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let length = min(size.width, size.height)
            let padding = length / 2 * 0.3
            let radius = length / 2 - padding

            context.drawLayer { ctx in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let length = min(size.width, size.height) * 0.9
                let path = Path { path in
                    let squareLength = length * 0.4
                    let topLeft = CGPoint(x: center.x - squareLength / 2, y: center.y - squareLength / 2)
                    let topRight = CGPoint(x: center.x + squareLength / 2, y: center.y - squareLength / 2)
                    let bottomRight = CGPoint(x: center.x + squareLength / 2, y: center.y + squareLength / 2)
                    let bottomLeft = CGPoint(x: center.x - squareLength / 2, y: center.y + squareLength / 2)

                    let top = CGPoint(x: center.x, y: (size.height - length) / 2)
                    let left = CGPoint(x: (size.width - length) / 2, y: center.y)
                    let right = CGPoint(x: (size.width + length) / 2, y: center.y)
                    let bottom = CGPoint(x: center.x, y: (size.height + length) / 2)

                    path.move(to: top)
                    path.addLine(to: topLeft)
                    path.addLine(to: left)
                    path.addLine(to: bottomLeft)
                    path.addLine(to: bottom)
                    path.addLine(to: bottomRight)
                    path.addLine(to: right)
                    path.addLine(to: topRight)
                    path.closeSubpath()
                }
                ctx.fill(path, with: .foreground)
            }

            let circlePath = Path { path in
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360),
                    clockwise: true
                )
            }

            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: center.x, y: center.y)
            transform = transform.rotated(by: .pi / 4)
            transform = transform.translatedBy(x: -center.x, y: -center.y)

            context.concatenate(transform)
            context.fill(circlePath, with: .foreground)
            context.blendMode = .destinationOut
            context.stroke(circlePath, with: .foreground, lineWidth: 1)
            context.blendMode = .normal

            let sectorRadius = with {
                let l = length / 2
                let delta = 4 * radius * radius - l * l
                return (1.732 * l - sqrt(delta)) / 2
            }

            func fillSector(center: CGPoint, angle: CGFloat) {
                let path = Path { path in
                    path.move(to: center)
                    path.addArc(
                        center: center,
                        radius: sectorRadius,
                        startAngle: .degrees(angle - 30),
                        endAngle: .degrees(angle + 30),
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                context.fill(path, with: .foreground)
                context.blendMode = .destinationOut
                context.stroke(path, with: .foreground, lineWidth: 1)
                context.blendMode = .normal
            }
            fillSector(center: .init(x: center.x, y: (size.height - length) / 2), angle: 90)
            fillSector(center: .init(x: center.x, y: (size.height + length) / 2), angle: 270)
            fillSector(center: .init(x: (size.width - length) / 2, y: center.y), angle: 0)
            fillSector(center: .init(x: (size.width + length) / 2, y: center.y), angle: 180)

            context.transform = .identity

            let highlightPath = Path { path in
                path.addArc(
                    center: center,
                    radius: radius * 0.84,
                    startAngle: .degrees(165),
                    endAngle: .degrees(195),
                    clockwise: false
                )
            }
            let highlightLineWidth: CGFloat = radius * 0.1
            context.stroke(
                highlightPath,
                with: .color(.white),
                style: .init(lineWidth: highlightLineWidth, lineCap: .round, lineJoin: .round)
            )
        }
        .rotationEffect(.degrees(60))
    }
}
