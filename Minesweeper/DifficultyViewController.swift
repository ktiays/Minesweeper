//
//  Created by ktiays on 2024/11/23.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import UIKit
import SwiftUI

final class DifficultyViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .boardBackground
        
        let difficultyView = _UIHostingView(rootView: DifficultySelectionView(difficultyDidSelect: { [weak self] item in
            let gameViewController = GameViewController(difficulty: item)
            gameViewController.modalPresentationStyle = .fullScreen
            self?.present(gameViewController, animated: true)
        }))
        difficultyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(difficultyView)
        NSLayoutConstraint.activate([
            difficultyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            difficultyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            difficultyView.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),
            difficultyView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300)
        ])
    }
}

enum Difficulty: String, Hashable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case expert = "Expert"
    case custom = "Custom"
}

extension Notification.Name {
    
    static let difficultyDidChange = Notification.Name("DifficultyDidChange")
}

struct DifficultyItem: Identifiable, Hashable {
    
    private let difficulty: Difficulty
    
    var id: Difficulty { difficulty }
    
    var title: String {
        difficulty.rawValue
    }
    
    let width: Int
    let height: Int
    let numberOfMines: Int
    
    init(difficulty: Difficulty, width: Int, height: Int, numberOfMines: Int) {
        self.difficulty = difficulty
        self.width = width
        self.height = height
        self.numberOfMines = numberOfMines
    }
}

fileprivate let difficulties: [Difficulty: DifficultyItem] = [
    .beginner: .init(difficulty: .beginner, width: 9, height: 9, numberOfMines: 10),
    .intermediate: .init(difficulty: .intermediate, width: 16, height: 16, numberOfMines: 40),
    .expert: .init(difficulty: .expert, width: 30, height: 16, numberOfMines: 99),
    .custom: .init(difficulty: .custom, width: 0, height: 0, numberOfMines: 0)
]

struct DifficultySelectionView: View {
    
    let difficultyDidSelect: (DifficultyItem) -> Void
    
    init(difficultyDidSelect: @escaping (DifficultyItem) -> Void) {
        self.difficultyDidSelect = difficultyDidSelect
    }
    
    @State private var selectedDifficulty: DifficultyItem?
    
    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                DifficultyView(difficulty: difficulties[.beginner]!, selection: $selectedDifficulty)
                DifficultyView(difficulty: difficulties[.intermediate]!, selection: $selectedDifficulty)
            }
            GridRow {
                DifficultyView(difficulty: difficulties[.expert]!, selection: $selectedDifficulty)
                DifficultyView(difficulty: difficulties[.custom]!, selection: $selectedDifficulty)
            }
        }
        .padding()
        .onChange(of: selectedDifficulty) { oldValue, newValue in
            guard let newValue else { return }
            difficultyDidSelect(newValue)
        }
    }
}

fileprivate struct DifficultyView: View {
    
    let difficulty: DifficultyItem
    @Binding var selection: DifficultyItem?
    
    init(difficulty: DifficultyItem, selection: Binding<DifficultyItem?>) {
        self.difficulty = difficulty
        _selection = selection
    }
    
    var body: some View {
        Button {
            selection = difficulty
        } label: {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .foregroundStyle(.largeButtonBackground)
                .overlay {
                    VStack(spacing: 6) {
                        Text(difficulty.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        if difficulty.id != .custom {
                            Text(verbatim: "\(difficulty.width) × \(difficulty.height)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                    }
                    .foregroundStyle(.white)
                }
        }
        .buttonStyle(ScaledButtonStyle(scale: 0.92))
    }
}
