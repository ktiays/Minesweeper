//
//  Created by ktiays on 2024/11/10.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import SwiftUI

enum Difficulty: String {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case expert = "Expert"
    case custom = "Custom"
}

extension Notification.Name {
    
    static let difficultyDidChange = Notification.Name("DifficultyDidChange")
}

struct DifficultyItem: Identifiable {
    
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
    
    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                DifficultyView(difficulty: .beginner)
                DifficultyView(difficulty: .intermediate)
            }
            GridRow {
                DifficultyView(difficulty: .expert)
                DifficultyView(difficulty: .custom)
            }
        }
        .padding()
    }
}

fileprivate struct DifficultyView: View {
    
    let difficulty: Difficulty
    private let item: DifficultyItem
    
    init(difficulty: Difficulty) {
        self.difficulty = difficulty
        self.item = difficulties[difficulty]!
    }
    
    var body: some View {
        Button {
            NotificationCenter.default.post(name: .difficultyDidChange, object: item)
        } label: {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .foregroundStyle(.largeButtonBackground)
                .overlay {
                    VStack(spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        if item.id != .custom {
                            Text("\(item.width) × \(item.height)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                    }
                    .foregroundStyle(.white)
                }
        }
        .buttonStyle(ScaledButtonStyle(scale: 0.92))
    }
}

#Preview {
    DifficultyView(difficulty: .beginner)
}
