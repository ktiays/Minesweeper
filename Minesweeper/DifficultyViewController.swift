//
//  Created by ktiays on 2024/11/23.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI
import UIKit

final class DifficultyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .boardBackground

        let difficultyView = _UIHostingView(
            rootView: DifficultySelectionView(difficultyDidSelect: { [weak self] item in
                let gameViewController = GameViewController(difficulty: item)
                gameViewController.transitioningDelegate = self
                self?.present(gameViewController, animated: true)
                #if targetEnvironment(macCatalyst)
                if let window = self?.view.window {
                    DispatchQueue.main.async {
                        let toolbar = ToolbarManager.shared.toolbar(for: window)
                        toolbar.updateHierarchy()
                    }
                }
                #endif
            })
        )
        difficultyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(difficultyView)
        NSLayoutConstraint.activate([
            difficultyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            difficultyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            difficultyView.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),
            difficultyView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
        ])
    }
}

enum Difficulty: Hashable, CustomLocalizedStringResourceConvertible {
    case beginner
    case intermediate
    case expert
    case custom

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .beginner:
            return "Beginner"
        case .intermediate:
            return "Intermediate"
        case .expert:
            return "Expert"
        case .custom:
            return "Custom"
        }
    }
}

struct DifficultyItem: Identifiable, Hashable {

    private let difficulty: Difficulty

    var id: Difficulty { difficulty }

    var title: String {
        .init(localized: difficulty.localizedStringResource)
    }

    let width: Int
    let height: Int
    let numberOfMines: Int
    let minSize: CGSize

    init(difficulty: Difficulty, width: Int, height: Int, numberOfMines: Int, minSize: CGSize) {
        self.difficulty = difficulty
        self.width = width
        self.height = height
        self.numberOfMines = numberOfMines
        self.minSize = minSize
    }
}

private let difficulties: [Difficulty: DifficultyItem] = [
    .beginner: .init(difficulty: .beginner, width: 9, height: 9, numberOfMines: 10, minSize: .init(width: 500, height: 600)),
    .intermediate: .init(difficulty: .intermediate, width: 16, height: 16, numberOfMines: 40, minSize: .init(width: 680, height: 760)),
    .expert: .init(difficulty: .expert, width: 30, height: 16, numberOfMines: 99, minSize: .init(width: 1300, height: 800)),
    .custom: .init(difficulty: .custom, width: 0, height: 0, numberOfMines: 0, minSize: .zero),
]

private struct DifficultySelectionView: View {

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
            selectedDifficulty = nil
        }
    }
}

private struct DifficultyView: View {

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

extension DifficultyViewController: UIViewControllerTransitioningDelegate {

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
