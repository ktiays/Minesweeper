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
                if item.id == .custom {
                    let alertController = AlertViewController(
                        title: String(localized: "Custom Level"),
                        message: String(localized: "Set the width, height, and number of mines for the custom level.")
                    ) { [weak self] in
                        CustomAlertContent {
                            self?.dismiss(animated: true)
                        } confirm: { difficulty in
                            self?.dismiss(animated: true) {
                                self?.startGame(with: difficulty)
                            }
                        }
                    }
                    alertController.customMode = true
                    self?.present(alertController, animated: true)
                } else {
                    self?.startGame(with: item)
                }
            })
        )
        difficultyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(difficultyView)
        NSLayoutConstraint.activate([
            difficultyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            difficultyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            difficultyView.topAnchor.constraint(equalTo: view.topAnchor),
            difficultyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func startGame(with difficulty: DifficultyItem) {
        let gameViewController = GameViewController(difficulty: difficulty)
        present(gameViewController, animated: true)
        #if targetEnvironment(macCatalyst)
        if let window = view.window {
            DispatchQueue.main.async {
                let toolbar = ToolbarManager.shared.toolbar(for: window)
                toolbar.updateHierarchy()
            }
        }
        #endif
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

func configureDifficulties() -> [Difficulty: DifficultyItem] {
    if UIDevice.current.userInterfaceIdiom == .phone {
        [
            .beginner: .init(difficulty: .beginner, width: 9, height: 9, numberOfMines: 10, minSize: .zero),
            .intermediate: .init(difficulty: .intermediate, width: 9, height: 16, numberOfMines: 30, minSize: .zero),
            .expert: .init(difficulty: .expert, width: 18, height: 32, numberOfMines: 99, minSize: .zero),
            .custom: .init(difficulty: .custom, width: 0, height: 0, numberOfMines: 0, minSize: .zero),
        ]
    } else {
        [
            .beginner: .init(difficulty: .beginner, width: 9, height: 9, numberOfMines: 10, minSize: .init(width: 500, height: 600)),
            .intermediate: .init(difficulty: .intermediate, width: 16, height: 16, numberOfMines: 40, minSize: .init(width: 680, height: 760)),
            .expert: .init(difficulty: .expert, width: 30, height: 16, numberOfMines: 99, minSize: .init(width: 1300, height: 800)),
            .custom: .init(difficulty: .custom, width: 0, height: 0, numberOfMines: 0, minSize: .zero),
        ]
    }
}

private struct DifficultySelectionView: View {

    let difficultyDidSelect: (DifficultyItem) -> Void
    private let difficulties = configureDifficulties()

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
        .frame(height: 500)
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

private struct CustomAlertContent: View {

    private let cancelAction: () -> Void
    private let confirmAction: (DifficultyItem) -> Void

    init(cancel: @escaping () -> Void, confirm: @escaping (DifficultyItem) -> Void) {
        self.cancelAction = cancel
        self.confirmAction = confirm
    }

    private enum FocusedField: Equatable {
        case width
        case height
        case numberOfMines
    }

    private static let boardMinWidth: Int = 3
    private static let boardMinHeight: Int = 3
    #if targetEnvironment(macCatalyst)
    private static let boardMaxWidth: Int = 99
    private static let boardMaxHeight: Int = 99
    #else
    private static let boardMaxWidth: Int = 50
    private static let boardMaxHeight: Int = 50
    #endif
    private static let minesMinCount: Int = 1
    
    @State private var width: Int = Self.boardMinWidth
    @State private var height: Int = Self.boardMinHeight
    @State private var numberOfMines: Int = Self.minesMinCount

    @FocusState private var focusedField: FocusedField?

    var body: some View {
        let textFieldWidth: CGFloat = 40
        let textFieldVerticalPadding: CGFloat = 10
        VStack(spacing: 16) {
            Grid(horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    TextField(String(), value: $width, formatter: NumberFormatter())
                        .focused($focusedField, equals: .width)
                        .frame(width: textFieldWidth)
                        .padding(.vertical, textFieldVerticalPadding)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder()
                                .opacity(0.3)
                        }
                    Image(systemName: "multiply")
                    TextField(String(), value: $height, formatter: NumberFormatter())
                        .focused($focusedField, equals: .height)
                        .frame(width: textFieldWidth)
                        .padding(.vertical, textFieldVerticalPadding)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder()
                                .opacity(0.3)
                        }
                }
                .font(.system(size: 20, weight: .semibold, design: .rounded))

                GridRow {
                    Text("Width")
                    Color.clear
                        .frame(width: 1, height: 1)
                    Text("Height")
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            VStack(spacing: 8) {
                TextField(String(), value: $numberOfMines, formatter: NumberFormatter())
                    .focused($focusedField, equals: .numberOfMines)
                    .frame(width: textFieldWidth)
                    .padding(.vertical, textFieldVerticalPadding)
                    .background {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .strokeBorder()
                            .opacity(0.3)
                    }
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Text("Mines")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            HStack {
                Button("Cancel") {
                    cancelAction()
                }
                Button("Start", role: .destructive) {
                    let item = DifficultyItem(difficulty: .custom, width: width, height: height, numberOfMines: numberOfMines, minSize: .zero)
                    confirmAction(item)
                }
            }
        }
        .multilineTextAlignment(.center)
        .keyboardType(.numberPad)
        .onChange(of: focusedField) { _, newValue in
            if newValue != .width && (width < Self.boardMinWidth || width > Self.boardMaxWidth) {
                width = min(max(width, Self.boardMinWidth), Self.boardMaxWidth)
            }
            if newValue != .height && (height < Self.boardMinHeight || height > Self.boardMaxHeight) {
                height = min(max(height, Self.boardMinHeight), Self.boardMaxHeight)
            }
            let maxMines = min(width * height - 1, 999)
            if newValue != .numberOfMines && (numberOfMines < Self.minesMinCount || numberOfMines > maxMines) {
                numberOfMines = min(max(numberOfMines, Self.minesMinCount), maxMines)
            }
        }
    }
}

#Preview {
    CustomAlertContent {

    } confirm: { _ in

    }
}
