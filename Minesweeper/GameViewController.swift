//
//  Created by ktiays on 2022/12/17.
//  Copyright (c) 2022 ktiays. All rights reserved.
//

import Combine
import SnapKit
import SwiftUI
import UIKit

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .boardBackground
        feedback.prepare()
        
        addChild(difficultyViewController)
        view.addSubview(difficultyViewController.view)
        difficultyViewController.didMove(toParent: self)
        difficultyViewController.view.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.greaterThanOrEqualTo(300)
            make.height.greaterThanOrEqualTo(300)
        }

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
        
//        let boardViewController = UIHostingController(
//            rootView: BoardView()
//                .environmentObject(minefield)
//        )
        let boardViewController = BoardViewController(minefield: minefield)
        boardViewController.view.backgroundColor = .clear
        addChild(boardViewController)
        view.addSubview(boardViewController.view)
        boardViewController.didMove(toParent: self)

        boardViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func configureMinefield(difficulty: DifficultyItem) {
        minefield = Minefield(
            width: difficulty.width,
            height: difficulty.height,
            numberOfMines: difficulty.numberOfMines
        )
        minefield?.$isCompleted.sink { [unowned self] completed in
            if !completed { return }
            
            let confetti = ConfettiViewController()
            guard let window = view.window else {
                return
            }

            feedback.impactOccurred()
            feedback.prepare()

            window.addSubview(confetti.view)
            confetti.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                confetti.view.removeFromSuperview()
            }
        }
        .store(in: &cancellables)
    }
}
