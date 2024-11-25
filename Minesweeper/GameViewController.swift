//
//  Created by ktiays on 2022/12/17.
//  Copyright (c) 2022 ktiays. All rights reserved.
//

import Combine
import SwiftUI
import UIKit

final class GameViewController: UIViewController {

    let difficulty: DifficultyItem

    private let minefield: Minefield
    private var cancellables: Set<AnyCancellable> = .init()

    private lazy var feedback: UIImpactFeedbackGenerator = .init(style: .light)

    #if targetEnvironment(macCatalyst)
    private weak var windowProxy: WindowProxy?
    #endif

    init(difficulty: DifficultyItem) {
        self.difficulty = difficulty
        minefield = .init(width: difficulty.width, height: difficulty.height, numberOfMines: difficulty.numberOfMines)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .boardBackground
        feedback.prepare()

        let boardViewController = BoardViewController(minefield: minefield)
        boardViewController.view.translatesAutoresizingMaskIntoConstraints = false
        let gameStatusBar = _UIHostingView(
            rootView: GameStatusBar(
                statusPublisher: boardViewController.$gameStatus,
                remainingMinesPublisher: boardViewController.$remainingMines,
                dismissAction: { [weak self] in
                    self?.dismiss(animated: true)
                }
            )
        )
        gameStatusBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gameStatusBar)
        addChild(boardViewController)
        view.insertSubview(boardViewController.view, belowSubview: gameStatusBar)
        boardViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            gameStatusBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            gameStatusBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            gameStatusBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            boardViewController.view.topAnchor.constraint(equalTo: gameStatusBar.bottomAnchor, constant: 6),
            boardViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 6),
            boardViewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -6),
            boardViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),
        ])

        #if targetEnvironment(macCatalyst)
        NotificationCenter.default.publisher(for: .MSPNSWindowDidCreateNotificationName)
            .sink { [unowned self] notification in
                guard let uiWindow = notification.userInfo?["window"] as? UIWindow else {
                    return
                }
                if uiWindow != view.window { return }

                guard let windowProxy = notification.object as? WindowProxy else {
                    return
                }
                self.windowProxy = windowProxy
            }
            .store(in: &cancellables)
        #endif
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        #if targetEnvironment(macCatalyst)
        if let window = view.window {
            let windowProxy = msp_windowProxyForUIWindow(window)
            let windowFrame = windowProxy.frame
            let center = windowFrame.center
            let targetSize = difficulty.minSize
            windowProxy.setFrame(
                .init(
                    x: center.x - targetSize.width / 2,
                    y: center.y - targetSize.height / 2,
                    width: targetSize.width,
                    height: targetSize.height
                ),
                display: true,
                animate: true
            )
            windowProxy.minSize = targetSize.applying(.init(scaleX: 0.5, y: 0.5))
            self.windowProxy = windowProxy
        }
        #endif
    }
}

struct GameStatusBar: View {

    let statusPublisher: AnyPublisher<BoardViewController.GameStatus, Never>
    let remainingMinesPublisher: AnyPublisher<Int, Never>
    let dismissAction: () -> Void

    @State private var status: BoardViewController.GameStatus = .idle
    private var isRunning: Bool {
        status == .playing
    }
    
    @State private var remainingMines: Int = 0

    @Environment(\.isMacCatalyst) private var isMacCatalyst

    init<P, R>(
        statusPublisher: P,
        remainingMinesPublisher: R,
        dismissAction: @escaping () -> Void
    )
    where
        P: Publisher, P.Output == BoardViewController.GameStatus, P.Failure == Never,
        R: Publisher, R.Output == Int, R.Failure == Never
    {
        self.statusPublisher = statusPublisher.eraseToAnyPublisher()
        self.remainingMinesPublisher = remainingMinesPublisher.eraseToAnyPublisher()
        self.dismissAction = dismissAction
    }

    var body: some View {
        HStack {
            Button {
                dismissAction()
            } label: {
                Image(systemName: "arrow.left")
                    .bold()
                    .frame(
                        width: isMacCatalyst ? 30 : 40,
                        height: isMacCatalyst ? 30 : 40
                    )
            }
            .buttonStyle(ToolbarButtonStyle())

            TimeView(isPaused: !isRunning)
                .opacity(status != .idle ? 1 : 0.28)
            Spacer()

            HStack {
                Text(verbatim: "\(remainingMines)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .foregroundStyle(remainingMines >= 0 ? .primary : Color.warningText)
                BombIcon()
                    .foregroundStyle(.accent.opacity(0.8))
                    .frame(width: 22, height: 22)
            }
            .padding(.leading, 11)
            .padding(.trailing, 8)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .foregroundStyle(.accent)
                    .opacity(0.16)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 5)
        .onReceive(statusPublisher) { status in
            withAnimation {
                self.status = status
            }
        }
        .onReceive(remainingMinesPublisher) { numberOfMines in
            withAnimation {
                self.remainingMines = numberOfMines
            }
        }
    }
}

struct ToolbarButtonStyle: ButtonStyle {

    @State private var isHovered: Bool = false
    @Environment(\.isMacCatalyst) private var isMacCatalyst

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                x: configuration.isPressed ? 0.8 : 1,
                y: configuration.isPressed ? 0.8 : 1
            )
            .offset(x: configuration.isPressed ? -4 : 0)
            .background {
                if isHovered {
                    RoundedRectangle(cornerRadius: isMacCatalyst ? 8 : 12, style: .continuous)
                        .foregroundStyle(.secondary)
                        .opacity(0.2)
                        .offset(x: configuration.isPressed ? -2 : 0)
                        .padding(.vertical, configuration.isPressed ? 2 : 0)
                }
            }
            .onHover { isHover in
                self.isHovered = isHover
            }
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    GameStatusBar(
        statusPublisher: PassthroughSubject().eraseToAnyPublisher(),
        remainingMinesPublisher: CurrentValueSubject(10).eraseToAnyPublisher()
    ) {

    }
    .frame(maxHeight: .infinity)
    .background {
        Color.boardBackground
            .ignoresSafeArea()
    }
}
