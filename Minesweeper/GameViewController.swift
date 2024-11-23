//
//  Created by ktiays on 2022/12/17.
//  Copyright (c) 2022 ktiays. All rights reserved.
//

import Combine
import SwiftSignal
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

    @Signal
    private var isGameRunning: Bool = false

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

        let gameStatusBar = BuilderHostingView { [unowned self] in
            HStack {
                TimeView(isPaused: !isGameRunning)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 5)
        }
        gameStatusBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gameStatusBar)
        NSLayoutConstraint.activate([
            gameStatusBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            gameStatusBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            gameStatusBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])

        let boardViewController = BoardViewController(minefield: minefield)
        boardViewController.view.translatesAutoresizingMaskIntoConstraints = false
        present(boardViewController, animated: true)
        addChild(boardViewController)
        view.insertSubview(boardViewController.view, belowSubview: gameStatusBar)
        boardViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            boardViewController.view.topAnchor.constraint(equalTo: gameStatusBar.bottomAnchor, constant: 6),
            boardViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 6),
            boardViewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -6),
            boardViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),
        ])
        boardViewController.$gameStatus.sink { [weak self] status in
            switch status {
            case .playing:
                self?.isGameRunning = true
            case .win, .lose:
                self?.isGameRunning = false
            default:
                break
            }
        }
        .store(in: &cancellables)

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
}

extension GameViewController: UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        BoardTransitionAnimator(isPresenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        BoardTransitionAnimator(isPresenting: false)
    }
}
