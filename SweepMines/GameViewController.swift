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
    private var gameStatusBar: _UIHostingView<GameStatusBar>!
    private var boardViewController: BoardViewController!

    #if targetEnvironment(macCatalyst)
    private var windowProxy: WindowProxy?
    private var toolbar: Toolbar? {
        if let window = view.window {
            return ToolbarManager.shared.toolbar(for: window)
        }
        return nil
    }
    private var popUpMenus: [MenuWindow] = []
    #else
    private var navigationBar: _UIHostingView<NavigationBar>!
    #endif

    init(difficulty: DifficultyItem) {
        self.difficulty = difficulty
        minefield = .init(width: difficulty.width, height: difficulty.height, numberOfMines: difficulty.numberOfMines)
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
        self.transitioningDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .boardBackground
        feedback.prepare()

        boardViewController = BoardViewController(minefield: minefield)
        gameStatusBar = _UIHostingView(
            rootView: GameStatusBar(
                statusPublisher: boardViewController.$gameStatus,
                remainingMinesPublisher: boardViewController.$remainingMines,
                dismissAction: { [weak self] in
                    self?.handleBackButton()
                }
            )
        )
        view.addSubview(gameStatusBar)
        addChild(boardViewController)
        view.insertSubview(boardViewController.view, belowSubview: gameStatusBar)
        boardViewController.didMove(toParent: self)

        #if !targetEnvironment(macCatalyst)
        navigationBar = _UIHostingView(
            rootView: NavigationBar(statusPublisher: boardViewController.$gameStatus) { [weak self] in
                self?.handleBackButton()
            } replayAction: { [weak self] context in
                self?.handleReplay(context)
            }
        )
        view.addSubview(navigationBar)
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
            if targetSize != .zero {
                if !windowProxy.isFullScreen {
                    let frame = CGRect(
                        x: center.x - targetSize.width / 2,
                        y: center.y - targetSize.height / 2,
                        width: targetSize.width,
                        height: targetSize.height
                    )
                    let screenFrame = windowProxy.screenVisibleFrame
                    windowProxy.setFrame(adjustRect(frame, boundedBy: screenFrame), display: true, animate: true)
                }
                windowProxy.minSize = targetSize.applying(.init(scaleX: 0.5, y: 0.5))
            }
            self.windowProxy = windowProxy

            let toolbar = ToolbarManager.shared.toolbar(for: window)
            let toolbarButton = NoSafeAreaHostingView(
                rootView: ToolbarButton(statusPublisher: boardViewController.$gameStatus) { [weak self] context in
                    self?.handleReplay(context)
                }
            )
            toolbar.replayButtonView = toolbarButton
        }
    }
    #endif

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let bounds = view.bounds
        let statusBarHeight = gameStatusBar.intrinsicContentSize.height
        let safeAreaInsets = view.safeAreaInsets
        let bottomInsets = safeAreaInsets.bottom
        #if targetEnvironment(macCatalyst)
        let topInsets = max(safeAreaInsets.top, ToolbarManager.defaultToolbarHeight)
        let bottomNavigationBarHeight: CGFloat = 0
        #else
        let topInsets = safeAreaInsets.top
        let bottomNavigationBarHeight = navigationBar.intrinsicContentSize.height
        navigationBar.frame = .init(
            x: 0,
            y: bounds.height - bottomNavigationBarHeight - bottomInsets,
            width: bounds.width,
            height: bottomNavigationBarHeight
        )
        #endif
        gameStatusBar.frame = .init(x: 0, y: topInsets, width: bounds.width, height: statusBarHeight)
        boardViewController.view.frame = .init(
            x: 0,
            y: gameStatusBar.frame.maxY,
            width: bounds.width,
            height: bounds.height - gameStatusBar.frame.maxY - bottomNavigationBarHeight - bottomInsets
        )
        .insetBy(dx: 6, dy: 6)
    }
    
    #if targetEnvironment(macCatalyst)
    private func closeAllMenus() {
        popUpMenus.forEach { $0.close() }
    }
    #endif
    
    private func handleBackButton() {
        if boardViewController!.gameStatus == .playing {
            #if targetEnvironment(macCatalyst)
            if let window = view.window {
                let menuViewController = UIHostingController(
                    rootView: SingleButtonMenu(
                        buttonContent: .init(
                            image: Image(systemName: "arrow.left"),
                            text: "Exit Game"
                        ),
                        message: "Your game is not finished yet, do you want to end and exit?",
                        action: { [weak self] in
                            self?.toolbar?.replayButtonView = nil
                            self?.closeAllMenus()
                            self?.presentingViewController?.dismiss(animated: true)
                        }
                    )
                )
                menuViewController.view.backgroundColor = .clear
                let menuWindow = MenuWindow(contentViewController: menuViewController)
                let statusBarOrigin = gameStatusBar.frame.origin
                menuWindow.popUp(
                    from: .init(
                        x: statusBarOrigin.x + 12,
                        y: statusBarOrigin.y + 5,
                        width: 30,
                        height: 30
                    ),
                    in: window
                )
                popUpMenus.append(menuWindow)
            }
            #else
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
            #endif
        } else {
            #if targetEnvironment(macCatalyst)
            toolbar?.replayButtonView = nil
            #endif
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
            #if targetEnvironment(macCatalyst)
            if let window = view.window {
                let menuViewController = UIHostingController(
                    rootView: SingleButtonMenu(
                        buttonContent: .init(
                            image: Image(systemName: "arrow.clockwise"),
                            text: "Restart Game"
                        ),
                        message: "Are you sure you want to restart the game? All progress will be lost.",
                        action: { [weak self] in
                            restartGame()
                            actionContext(true)
                            self?.closeAllMenus()
                        }
                    )
                )
                menuViewController.view.backgroundColor = .clear
                let menuWindow = MenuWindow(contentViewController: menuViewController)
                let toolbarFrame = toolbar?.frame ?? .init(origin: .zero, size: .init(width: window.bounds.width, height: 52))
                menuWindow.popUp(
                    from: .init(
                        x: toolbarFrame.maxX - 42,
                        y: toolbarFrame.minY + 11,
                        width: 30,
                        height: 30
                    ),
                    in: window
                )
                popUpMenus.append(menuWindow)
            }
            #else
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
            #endif
        } else {
            restartGame()
            actionContext(true)
        }
    }
}

extension GameViewController: UIViewControllerTransitioningDelegate {

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        BoardTransitionAnimator(isPresenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        BoardTransitionAnimator(isPresenting: false)
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
