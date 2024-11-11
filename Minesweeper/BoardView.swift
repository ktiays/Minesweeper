//
//  Created by ktiays on 2024/11/4.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI
import With

struct MinefieldLayout: Layout {

    let width: Int
    let height: Int
    let spacing: CGFloat

    init(width: Int, height: Int, spacing: CGFloat = 2) {
        self.width = width
        self.height = height
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        idealSize(for: proposal.replacingUnspecifiedDimensions())
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let cellLength = cellLength(for: bounds.size)

        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let cellBounds = CGRect(
                    x: bounds.minX + spacing + CGFloat(x) * (cellLength + spacing),
                    y: bounds.minY + spacing + CGFloat(y) * (cellLength + spacing),
                    width: cellLength,
                    height: cellLength
                )
                if index >= subviews.count {
                    break
                }
                let subview = subviews[index]
                subview.place(at: cellBounds.origin, proposal: .init(cellBounds.size))
            }
        }
    }
    
    private func cellLength(for size: CGSize) -> CGFloat {
        let widthSpecified = (size.width - spacing * CGFloat(width + 1)) / CGFloat(width)
        let heightSpecified = (size.height - spacing * CGFloat(height + 1)) / CGFloat(height)
        return if size.width / size.height > CGFloat(width) / CGFloat(height) {
            heightSpecified
        } else {
            widthSpecified
        }
    }

    private func idealSize(for size: CGSize) -> CGSize {
        let cellLength = cellLength(for: size)
        return CGSize(
            width: cellLength * CGFloat(width) + spacing * CGFloat(width + 1),
            height: cellLength * CGFloat(height) + spacing * CGFloat(height + 1)
        )
    }
}

private let textColorMap: [Int: Color] = [
    1: .oneText,
    2: .twoText,
    3: .threeText,
    4: .fourText,
    5: .fiveText,
    6: .sixText,
    7: .sevenText,
    8: .eightText,
]

private func numberTextColor(for number: Int) -> Color {
    textColorMap[number, default: .primary]
}

struct BoardView: View {

    @EnvironmentObject private var minefield: Minefield

    @Environment(\.colorScheme) private var colorScheme

    @State private var animationAnchor: Minefield.Position?
    @State private var interactionAnchor: Minefield.Position?
    @State private var tappedAnchor: Minefield.Position?
    @State private var explodeAnchor: Minefield.Position?

    var body: some View {
        MinefieldLayout(width: minefield.width, height: minefield.height, spacing: 6) {
            ForEach(0..<minefield.height, id: \.self) { y in
                ForEach(0..<minefield.width, id: \.self) { x in
                    PieceView(
                        x: x,
                        y: y,
                        animationAnchor: $animationAnchor.animation(nil),
                        interactionAnchor: $interactionAnchor,
                        tappedAnchor: $tappedAnchor,
                        explodeAnchor: $explodeAnchor
                    )
                }
            }
        }
        .padding(4)
        .sensoryFeedback(.error, trigger: minefield.isExploded)
    }
}

struct PieceView: View {

    @EnvironmentObject private var minefield: Minefield
    @Environment(\.colorScheme) private var colorScheme

    @Binding var animationAnchor: Minefield.Position?
    @Binding var interactionAnchor: Minefield.Position?
    /// The position of the cleared piece that is tapped.
    @Binding var tappedAnchor: Minefield.Position?
    @Binding var explodeAnchor: Minefield.Position?

    let x: Int
    let y: Int

    @State private var isDragging: Bool = false
    @State private var expandMenu: Bool = false
    /// A Boolean value that indicates whether the piece is pressed.
    @State private var isPressed: Bool = false
    @State private var translation: CGSize = .zero

    @State private var topContentBounds: CGRect = .zero
    @State private var bottomContentBounds: CGRect = .zero

    @State private var isInTopContent: Bool = false
    @State private var isInBottomContent: Bool = false

    @State private var topContentFeedback: Bool = false
    @State private var bottomContentFeedback: Bool = false

    private var elevateViewHierarchy: Bool {
        guard let interactionAnchor = interactionAnchor else {
            return false
        }

        return x == interactionAnchor.x && y == interactionAnchor.y
    }
    
    private var isGameOver: Bool {
        minefield.isExploded || minefield.isCompleted
    }

    init(
        x: Int,
        y: Int,
        animationAnchor: Binding<Minefield.Position?>,
        interactionAnchor: Binding<Minefield.Position?>,
        tappedAnchor: Binding<Minefield.Position?>,
        explodeAnchor: Binding<Minefield.Position?>
    ) {
        self.x = x
        self.y = y
        _animationAnchor = animationAnchor
        _interactionAnchor = interactionAnchor
        _tappedAnchor = tappedAnchor
        _explodeAnchor = explodeAnchor
    }

    var body: some View {
        let position = Minefield.Position(x: x, y: y)
        let location = minefield.location(at: position)
        ZStack {
            // MARK: Grid & Numbers
            if location.isCleared {
                Group {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke()
                        .shadow(color: .black.opacity(colorScheme == .light ? 0.7 : 1), radius: 4, x: 2, y: 2)
                    RoundedRectangle(cornerRadius: 12)
                        .stroke()
                        .shadow(color: .white.opacity(colorScheme == .dark ? 0.4 : 1), radius: 3, x: -2, y: -2)

                    let count = location.numberOfMinesAround
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(numberTextColor(for: count))
                            .contentTransition(.numericText())
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    animationAnchor = position
                    withAnimation(.spring(duration: 0.24)) {
                        minefield.multiRelease(at: position)
                        if minefield.isExploded {
                            explodeAnchor = position
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .mask {
            RoundedRectangle(cornerRadius: 12)
                .padding(2)
        }
        .overlay {
            let isExploded = minefield.isExploded
            let explodeDelay = calculateDelay(x: x, y: y, anchor: explodeAnchor) * 0.8
            // The animation for the explosion.
            let explodeStartStageAnimation: Animation = .spring(duration: 0.2)
            let explodeFallingStageAnimation: Animation = .spring(response: 0.6, dampingFraction: 0.5)
            let pieceOpacity: Double = isExploded && !location.hasMine ? (colorScheme == .light ? 0.2 : 0.2) : 1

            // MARK: Uncovered Piece
            GeometryReader { geometry in
                Color.clear.onAppear {
                    let contentBounds = geometry.frame(in: .global)
                    topContentBounds = contentBounds.offsetBy(dx: 0, dy: -contentBounds.height * 1.2)
                        .insetBy(dx: -20, dy: -20)
                    topContentBounds.top = 0
                    bottomContentBounds = contentBounds.offsetBy(dx: 0, dy: contentBounds.height * 1.2)
                        .insetBy(dx: -20, dy: -20)
                    bottomContentBounds.bottom += 1e3
                }
                if !location.isCleared {
                    let length = min(geometry.size.width, geometry.size.height)
                    let radius: CGFloat = length / 2
                    with {
                        let targetRadius: CGFloat =
                            if expandMenu {
                                radius + (isInTopContent ? 30.0 : 10.0)
                            } else {
                                0.0
                            }
                        FlagContent(direction: .top, radius: targetRadius, isHighlighted: isInTopContent && expandMenu)
                            .blur(radius: expandMenu ? 0 : 12)
                            .sensoryFeedback(.impact(weight: .light), trigger: topContentFeedback)
                            .transition(.identity)
                            .onChange(of: isInTopContent) { _, newValue in
                                if newValue {
                                    topContentFeedback.toggle()
                                }
                            }
                    }
                    with {
                        let targetRadius: CGFloat =
                            if expandMenu {
                                radius + (isInBottomContent ? 30.0 : 10.0)
                            } else {
                                0.0
                            }
                        FlagContent(direction: .bottom, radius: targetRadius, isHighlighted: isInBottomContent && expandMenu) {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .opacity(isInBottomContent ? 1 : 0)
                                .scaleEffect(isInBottomContent ? 1 : 0.2)
                        }
                        .blur(radius: expandMenu ? 0 : 12)
                        .sensoryFeedback(.impact(weight: .light), trigger: bottomContentFeedback)
                        .transition(.identity)
                        .onChange(of: isInBottomContent) { _, newValue in
                            if newValue {
                                bottomContentFeedback.toggle()
                            }
                        }
                    }

                    RoundedRectangle(cornerRadius: expandMenu ? (geometry.size.width / 2) : 12)
                        .overlay {
                            ZStack(alignment: .topTrailing) {
                                let isFlagged = (location.flag == .flag)
                                let showMine = isExploded && location.hasMine
                                let tagMode = isFlagged && showMine
                                if showMine {
                                    BombIcon()
                                        .foregroundStyle(.black.opacity(0.46))
                                        .padding(tagMode ? 8 : 6)
                                        .offset(x: tagMode ? -3 : 0, y: tagMode ? 3 : 0)
                                }
                                if isFlagged {
                                    Image(systemName: "flag.fill")
                                        .font(.system(size: tagMode ? 13 : 20, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(4)
                        }
                        .scaleEffect(isPressed ? 0.9 : 1)
                        .offset(calculatePieceOffset())
                        .transition(
                            .scale.combined(with: .opacity)
                                .animation(
                                    .spring(dampingFraction: 0.7)
                                        .delay(calculateDelay(x: x, y: y, anchor: animationAnchor))
                                )
                        )
                }
            }
            .phaseAnimator([0, 1], trigger: isExploded) { content, phase in
                let displayInRed: Bool = (isExploded && location.hasMine)
                content
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                phase == 1 ? .red : (displayInRed ? .pieceExplodedTopLeading : .pieceTopLeading),
                                phase == 1 ? .red : (displayInRed ? .pieceExplodedBottomTrailing : .pieceBottomTrailing),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(phase == 1 ? 1.15 : 1)
            } animation: { phase in
                if phase == 1 {
                    explodeStartStageAnimation.delay(explodeDelay)
                } else {
                    explodeFallingStageAnimation
                }
            }
            .phaseAnimator([0, 1], trigger: isExploded) { content, phase in
                let distance = distance(x: x, y: y, anchor: explodeAnchor)
                let theta = atan2(distance.y, distance.x)
                let hypotenuse = -distance.norm * 4
                let offset: CGSize = .init(
                    width: hypotenuse * cos(theta),
                    height: hypotenuse * sin(theta)
                )
                content
                    .offset(phase == 1 ? offset : .zero)
            } animation: { phase in
                if phase == 1 {
                    explodeStartStageAnimation
                } else {
                    explodeFallingStageAnimation
                }
            }
            .opacity(pieceOpacity)
            .padding(1)
            .animation(
                explodeFallingStageAnimation.delay(explodeDelay),
                value: isExploded
            )
        }
        .zIndex(elevateViewHierarchy ? Double(minefield.count) : 0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    interactionAnchor = position

                    withAnimation(.spring(duration: 0.24)) {
                        isPressed = true
                        
                        if isGameOver { return }

                        if location.isCleared {
                            if location.numberOfMinesAround > 0 {
                                tappedAnchor = position
                            }
                        } else {
                            let translation = value.translation
                            self.translation = translation

                            let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
                            if distance > 25 {
                                expandMenu = true
                            }

                            let location = value.location
                            isInTopContent = topContentBounds.contains(location)
                            isInBottomContent = bottomContentBounds.contains(location)
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(duration: 0.24)) {
                        isPressed = false
                        
                        if isGameOver { return }
                        
                        translation = .zero
                        if !expandMenu {
                            animationAnchor = position

                            tappedAnchor = nil
                            isDragging = false
                            minefield.clearMine(at: position)

                            if minefield.isExploded {
                                explodeAnchor = position
                            }
                        } else {
                            expandMenu = false

                            if isInBottomContent {
                                let flag: Minefield.Flag =
                                    if location.flag == .flag {
                                        .none
                                    } else {
                                        .flag
                                    }
                                minefield.changeFlag(to: flag, at: position)
                            }
                        }
                    }
                }
        )
    }

    public func rubberBandOffset(_ offset: CGFloat, range: CGFloat) -> CGFloat {
        let coefficient: CGFloat = 0.1
        // Check if offset and range are positive.
        if offset < 0 || range <= 0 {
            return 0
        }
        return (1 - (1 / (offset / range * coefficient + 1))) * range
    }

    private func calculatePieceOffset() -> CGSize {
        let range: CGFloat = 5
        let width = translation.width
        let height = translation.height
        let x = rubberBandOffset(abs(width), range: range)
        let y = rubberBandOffset(abs(height), range: range)
        return .init(width: width < 0 ? -x : x, height: height < 0 ? -y : y)
    }

    private func distance(x: Int, y: Int, anchor: Minefield.Position?) -> CGPoint {
        guard let animationAnchor = anchor else {
            return .zero
        }

        let xDistance = CGFloat(animationAnchor.x - x)
        let yDistance = CGFloat(animationAnchor.y - y)
        return .init(x: xDistance, y: yDistance)
    }

    private func calculateDelay(x: Int, y: Int, anchor: Minefield.Position?) -> Double {
        distance(x: x, y: y, anchor: anchor).norm * 0.1
    }

    private struct FlagArc: Shape {

        enum Direction {
            case top
            case bottom
        }

        let direction: Direction
        var radius: CGFloat

        var animatableData: Double {
            get { radius }
            set { radius = newValue }
        }

        init(direction: Direction = .bottom, radius: CGFloat) {
            self.radius = radius
            self.direction = direction
        }

        nonisolated func path(in rect: CGRect) -> Path {
            Path { path in
                let angle: Double = 40
                let size = rect.size
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let targetAngle: Double =
                    switch direction {
                    case .bottom:
                        90
                    case .top:
                        270
                    }
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(targetAngle - angle / 2),
                    endAngle: .degrees(targetAngle + angle / 2),
                    clockwise: false
                )
            }
        }
    }

    private struct FlagContent<Symbol>: View where Symbol: View {

        let direction: FlagArc.Direction
        let radius: CGFloat
        let isHighlighted: Bool
        let symbol: Symbol

        init(direction: FlagArc.Direction, radius: CGFloat, isHighlighted: Bool) where Symbol == EmptyView {
            self.init(direction: direction, radius: radius, isHighlighted: isHighlighted) {
                EmptyView()
            }
        }

        init(direction: FlagArc.Direction, radius: CGFloat, isHighlighted: Bool, @ViewBuilder _ symbol: () -> Symbol) {
            self.direction = direction
            self.radius = radius
            self.isHighlighted = isHighlighted
            self.symbol = symbol()
        }

        var body: some View {
            let normalLineWidth: CGFloat = 10
            let highlightedLineWidth: CGFloat = 40
            FlagArc(direction: direction, radius: radius)
                .stroke(
                    style: .init(
                        lineWidth: isHighlighted ? highlightedLineWidth : normalLineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .foregroundStyle(.orange)
                .overlay {
                    let yOffset =
                        switch direction {
                        case .top:
                            -radius
                        case .bottom:
                            radius
                        }
                    symbol
                        .offset(y: yOffset)
                }
        }
    }
}

// MARK: - Bomb Icon

struct BombIcon: View {

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
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

// MARK: - Extensions

extension CGRect {

    var top: CGFloat {
        get { minY }
        set {
            let diff = newValue - minY
            origin.y += diff
            size.height -= diff
        }
    }

    var left: CGFloat {
        get { minX }
        set {
            let diff = newValue - minX
            origin.x += diff
            size.width -= diff
        }
    }

    var bottom: CGFloat {
        get { maxY }
        set { size.height = newValue - minY }
    }

    var right: CGFloat {
        get { maxX }
        set { size.width = newValue - minX }
    }
}

extension CGPoint {

    var norm: CGFloat {
        sqrt(x * x + y * y)
    }
}

// MARK: - Previews

#Preview("Board") {
    BoardView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color.orange.opacity(0.1)
                .ignoresSafeArea()
        }
        .environmentObject(Minefield(width: 6, height: 10, numberOfMines: 12))
}

#Preview("Bomb") {
    BombIcon()
}
