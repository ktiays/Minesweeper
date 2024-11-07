//
//  Created by ktiays on 2022/12/17.
//  Copyright (c) 2022 ktiays. All rights reserved.
//

import Combine
import SnapKit
import SwiftUI
import UIKit

final class GameViewController: UIViewController {

    private var minefield: Minefield = .init(width: 6, height: 10, numberOfMines: 10)
    private var cancellables: Set<AnyCancellable> = .init()
    
    private lazy var feedback: UIImpactFeedbackGenerator = .init(style: .light)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .boardBackground
        feedback.prepare()

        let boardViewController = UIHostingController(
            rootView: BoardView()
                .environmentObject(minefield)
        )
        boardViewController.view.backgroundColor = .clear
        addChild(boardViewController)
        view.addSubview(boardViewController.view)
        boardViewController.didMove(toParent: self)

        boardViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        minefield.$isCompleted.sink { [unowned self] completed in
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
