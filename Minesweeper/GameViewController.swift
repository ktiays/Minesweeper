//
//  Created by ktiays on 2022/12/17.
//  Copyright (c) 2022 ktiays. All rights reserved.
//

import Combine
import SwiftUI
import UIKit

final class GameViewController: UIViewController {

    let difficulty: DifficultyItem

    private var minefield: Minefield!
    private var cancellables: Set<AnyCancellable> = .init()

    private lazy var feedback: UIImpactFeedbackGenerator = .init(style: .light)
    private var boardViewController: BoardViewController!

    #if targetEnvironment(macCatalyst)
    private var windowProxy: WindowProxy?
    private var toolbarHostingView: MSPUIHostingView?

    deinit {
        toolbarHostingView?.removeFromSuperview()
        toolbarHostingView = nil
    }
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

        boardViewController = BoardViewController(minefield: minefield)
        boardViewController.view.translatesAutoresizingMaskIntoConstraints = false
        let gameStatusBar = _UIHostingView(
            rootView: GameStatusBar(
                statusPublisher: boardViewController.$gameStatus,
                remainingMinesPublisher: boardViewController.$remainingMines,
                dismissAction: { [weak self] in
                    self?.handleBackButton()
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
        let toolbarContainer = UIView()
        toolbarContainer.translatesAutoresizingMaskIntoConstraints = false

        let toolbarButton = NoSafeAreaHostingView(
            rootView: ToolbarButton(statusPublisher: boardViewController.$gameStatus) { [weak self] context in
                self?.handleReplay(context)
            }
        )
        #else
        let navigationBar = _UIHostingView(
            rootView: NavigationBar(statusPublisher: boardViewController.$gameStatus) { [weak self] in
                self?.handleBackButton()
            } replayAction: { [weak self] context in
                self?.handleReplay(context)
            }
        )
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        NSLayoutConstraint.activate([
            navigationBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
        #endif
    }

    #if targetEnvironment(macCatalyst)
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        if let window = view.window, self.windowProxy == nil {
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
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        guard windowProxy != nil, let toolbarHostingView else {
            return
        }

        let minToolbarHeight: CGFloat = 52
        let containerHeight = view.bounds.height
        toolbarHostingView.frame = .init(
            x: 0,
            y: containerHeight - minToolbarHeight,
            width: view.bounds.width,
            height: minToolbarHeight
        )
    }
    #endif

    private func handleBackButton() {
        if boardViewController!.gameStatus == .playing {
            let alert = AlertViewController(
                title: String(localized: "Exit Game"),
                message: String(localized: "Your game is not finished yet, do you want to end and exit?")
            ) {
                Button(String(localized: "Cancel"), role: .cancel) { [weak self] in
                    self?.dismiss(animated: true)
                }
                Button(String(localized: "Confirm"), role: .destructive) { [weak self] in
                    self?.presentingViewController?.dismiss(animated: true)
                }
            }
            self.present(alert, animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func replay(_ sender: Any) {
        handleReplay(.init { _ in })
    }
    
    private func handleReplay(_ actionContext: ReplayButton.ActionContext) {
        func restartGame() {
            minefield = .init(width: difficulty.width, height: difficulty.height, numberOfMines: difficulty.numberOfMines)
            boardViewController.reset(with: minefield)
        }
        if boardViewController!.gameStatus == .playing {
            let alert = AlertViewController(
                title: String(localized: "Restart Game"),
                message: String(localized: "Are you sure you want to restart the game? All progress will be lost.")
            ) {
                Button(String(localized: "Cancel"), role: .cancel) { [weak self] in
                    actionContext(false)
                    self?.dismiss(animated: true)
                }
                Button(String(localized: "Restart"), role: .destructive) { [weak self] in
                    guard let self else { return }
                    restartGame()
                    actionContext(true)
                    dismiss(animated: true)
                }
            }
            alert.transitioningDelegate = alert
            self.present(alert, animated: true)
        } else {
            restartGame()
            actionContext(true)
        }
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
    @State private var seconds: Int = 0

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
            if isMacCatalyst {
                BackButton(action: dismissAction)
            }

            TimeView(seconds: $seconds, isPaused: !isRunning)
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
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .foregroundStyle(.accent)
                    .opacity(0.16)
            }
        }
        .padding(.horizontal, isMacCatalyst ? 12 : 16)
        .padding(.top, 5)
        .onReceive(statusPublisher) { status in
            withAnimation {
                if status == .idle {
                    seconds = 0
                }
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

struct BackButtonStyle: ButtonStyle {

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

struct ReplayButtonStyle: ButtonStyle {

    @State private var isHovered: Bool = false
    @Environment(\.isMacCatalyst) private var isMacCatalyst

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                if isHovered {
                    RoundedRectangle(cornerRadius: isMacCatalyst ? 8 : 12, style: .continuous)
                        .foregroundStyle(.secondary)
                        .opacity(0.2)
                }
            }
            .scaleEffect(
                x: configuration.isPressed ? 0.9 : 1,
                y: configuration.isPressed ? 0.9 : 1
            )
            .onHover { isHover in
                self.isHovered = isHover
            }
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct BackButton: View {

    private let action: () -> Void

    @Environment(\.isMacCatalyst) private var isMacCatalyst

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "arrow.left")
                .bold()
                .frame(width: isMacCatalyst ? 30 : 40, height: isMacCatalyst ? 30 : 40)
        }
        .buttonStyle(BackButtonStyle())
    }
}

struct ReplayButton: View {

    @Environment(\.isMacCatalyst) private var isMacCatalyst

    @State private var count: Int = 0
    private let disabled: Bool
    private let action: (ActionContext) -> Void

    init(disabled: Bool = false, action: @escaping (ActionContext) -> Void) {
        self.disabled = disabled
        self.action = action
    }

    struct ActionContext {
        let completion: (Bool) -> Void

        func callAsFunction(_ handled: Bool) {
            completion(handled)
        }
    }

    var body: some View {
        Button {
            let context = ActionContext { handled in
                if handled {
                    withAnimation {
                        count += 1
                    }
                }
            }
            action(context)
        } label: {
            Image(systemName: "arrow.clockwise")
                .bold()
                .modifier(SymbolRotation(value: count))
                .frame(width: isMacCatalyst ? 30 : 40, height: isMacCatalyst ? 30 : 40)
                .opacity(disabled ? 0.2 : 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(ReplayButtonStyle())
        .disabled(disabled)
    }

    private struct SymbolRotation: ViewModifier {
        let value: Int

        func body(content: Content) -> some View {
            if #available(iOS 18.0, macOS 15.0, *) {
                content.symbolEffect(.rotate, options: .speed(2), value: value)
            }
        }
    }
}

#if targetEnvironment(macCatalyst)
extension Notification.Name {
    static let toolbarReplayButtonItemDidChange = Notification.Name("toolbarReplayButtonItemDidChange")
}

extension NSToolbarItem.Identifier {
    static let replayButton = NSToolbarItem.Identifier("ReplayButton")
}

struct ToolbarButton: View {
    let statusPublisher: AnyPublisher<BoardViewController.GameStatus, Never>
    let replayAction: (ReplayButton.ActionContext) -> Void

    @State private var isReplayButtonDisabled: Bool = true

    init<P>(
        statusPublisher: P,
        replayAction: @escaping (ReplayButton.ActionContext) -> Void
    ) where P: Publisher, P.Output == BoardViewController.GameStatus, P.Failure == Never {
        self.statusPublisher = statusPublisher.eraseToAnyPublisher()
        self.replayAction = replayAction
    }

    var body: some View {
        ReplayButton(disabled: isReplayButtonDisabled) { context in
            replayAction(context)
        }
        .padding(.horizontal, 10)
        .onReceive(statusPublisher) { status in
            withAnimation {
                isReplayButtonDisabled = status == .idle
            }
        }
    }
}
#else
struct NavigationBar: View {

    let statusPublisher: AnyPublisher<BoardViewController.GameStatus, Never>
    let dismissAction: () -> Void
    let replayAction: (ReplayButton.ActionContext) -> Void

    @Environment(\.isMacCatalyst) private var isMacCatalyst
    @State private var isReplayDisabled: Bool = false

    init<P>(
        statusPublisher: P,
        dismissAction: @escaping () -> Void,
        replayAction: @escaping (ReplayButton.ActionContext) -> Void
    ) where P: Publisher, P.Output == BoardViewController.GameStatus, P.Failure == Never {
        self.statusPublisher = statusPublisher.eraseToAnyPublisher()
        self.dismissAction = dismissAction
        self.replayAction = replayAction
    }

    var body: some View {
        HStack {
            BackButton(action: dismissAction)
            Spacer()
            ReplayButton(disabled: isReplayDisabled, action: replayAction)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .onReceive(statusPublisher) { status in
            withAnimation {
                isReplayDisabled = status == .idle
            }
        }
    }
}
#endif
