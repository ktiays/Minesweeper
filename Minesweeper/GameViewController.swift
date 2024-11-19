//
//  Created by ktiays on 2022/12/17.
//  Copyright (c) 2022 ktiays. All rights reserved.
//

import Combine
import SwiftUI
import UIKit
import SwiftSignal

final class GameViewController: UIViewController {

    private var minefield: Minefield?
    private var cancellables: Set<AnyCancellable> = .init()

    private lazy var feedback: UIImpactFeedbackGenerator = .init(style: .light)
    
    #if targetEnvironment(macCatalyst)
    private weak var windowProxy: WindowProxy?
    #endif
    
    private lazy var difficultyViewController: UIHostingController<DifficultySelectionView> = {
        let difficultyViewController = UIHostingController(rootView: DifficultySelectionView())
        difficultyViewController.view.backgroundColor = .clear
        return difficultyViewController
    }()
    
    @Signal
    private var isGameRunning: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .boardBackground
        feedback.prepare()
        
        difficultyViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(difficultyViewController)
        view.addSubview(difficultyViewController.view)
        difficultyViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            difficultyViewController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            difficultyViewController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            difficultyViewController.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),
            difficultyViewController.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 300)
        ])
        
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.publisher(for: .difficultyDidChange)
            .sink { [unowned self] notification in
                guard let item = notification.object as? DifficultyItem else {
                    return
                }
                
                switchToBoard(difficulty: item)
            }
            .store(in: &cancellables)

        #if targetEnvironment(macCatalyst)
        notificationCenter.publisher(for: .MSPNSWindowDidCreateNotificationName)
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
    
    private func switchToBoard(difficulty: DifficultyItem) {
        configureMinefield(difficulty: difficulty)
        guard let minefield else { return }
        
        difficultyViewController.willMove(toParent: nil)
        difficultyViewController.view.removeFromSuperview()
        difficultyViewController.removeFromParent()
        
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
            gameStatusBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        let boardViewController = BoardViewController(minefield: minefield)
        boardViewController.view.backgroundColor = .clear
        boardViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(boardViewController)
        view.insertSubview(boardViewController.view, belowSubview: gameStatusBar)
        boardViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            boardViewController.view.topAnchor.constraint(equalTo: gameStatusBar.bottomAnchor, constant: 6),
            boardViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 6),
            boardViewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -6),
            boardViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6)
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
    }
    
    private func configureMinefield(difficulty: DifficultyItem) {
        minefield = Minefield(
            width: difficulty.width,
            height: difficulty.height,
            numberOfMines: difficulty.numberOfMines
        )
    }
}
