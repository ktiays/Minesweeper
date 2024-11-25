//
//  Created by ktiays on 2024/11/4.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import Combine
import Foundation
import QuartzCore

public final class Minefield {

    public struct Position: Hashable, CustomStringConvertible {
        public var x: Int
        public var y: Int

        public var description: String {
            "(\(x), \(y))"
        }

        public init(x: Int, y: Int) {
            self.x = x
            self.y = y
        }
    }

    public struct Location: Hashable {
        public var hasMine: Bool = false
        public var isCleared: Bool = false
        public var flag: Flag = .none

        public var numberOfMinesAround: Int = 0
    }

    public enum Flag: CustomStringConvertible, CaseIterable {
        case none
        case flag
        case maybe

        public var description: String {
            switch self {
            case .none:
                "None"
            case .flag:
                "Flag"
            case .maybe:
                "Maybe"
            }
        }

        public func next() -> Flag {
            switch self {
            case .none:
                .flag
            case .flag:
                .maybe
            case .maybe:
                .none
            }
        }
    }

    public let width: Int
    public let height: Int
    public let numberOfMines: Int

    public var count: Int {
        width * height
    }

    public var autoFlag: Bool = false

    public private(set) var locations: [Location]

    private(set) var numberOfCleared: Int = 0
    private(set) var numberOfFlagged: Int = 0
    private var isPlacedMines: Bool = false

    public private(set) var isExploded: Bool = false

    public private(set) var isCompleted: Bool = false

    public init(width: Int, height: Int, numberOfMines: Int) {
        self.width = width
        self.height = height
        self.numberOfMines = numberOfMines
        self.locations = Array(repeating: Location(), count: width * height)
    }

    public func hasMineAt(x: Int, y: Int) -> Bool {
        locationAt(x: x, y: y).hasMine
    }

    private func flagAt(x: Int, y: Int) -> Flag {
        locationAt(x: x, y: y).flag
    }

    public func locationAt(x: Int, y: Int) -> Location {
        let index = y * width + x
        return locations[index]
    }

    public func location(at position: Position) -> Location {
        locationAt(x: position.x, y: position.y)
    }

    public func changeFlag(to flag: Flag, at position: Position) {
        let location = location(at: position)
        if location.isCleared || location.flag == flag {
            return
        }

        if flag == .flag {
            numberOfFlagged += 1
        } else if location.flag == .flag {
            numberOfFlagged -= 1
        }

        locations[position.y * width + position.x].flag = flag
    }

    public func neighbour(of position: Position) -> [Position] {
        var positions: [Position] = []
        for y in -1...1 {
            for x in -1...1 {
                if x == 0 && y == 0 {
                    continue
                }

                let nx = position.x + x
                let ny = position.y + y
                if nx >= 0 && nx < width && ny >= 0 && ny < height {
                    positions.append(Position(x: nx, y: ny))
                }
            }
        }
        return positions
    }

    public func placeMine(avoiding position: Position) {
        let now = CACurrentMediaTime()

        let neighbours = self.neighbour(of: position)

        var mines: [Bool] = Array(repeating: true, count: numberOfMines)
        mines.append(contentsOf: Array(repeating: false, count: width * height - numberOfMines - neighbours.count - 1))
        mines.shuffle()

        var avoidings = neighbours.map({ $0.y * width + $0.x })
        avoidings.append(position.y * width + position.x)
        avoidings.sort()
        for i in avoidings {
            mines.insert(false, at: i)
        }

        var locations = self.locations
        for (index, hasMine) in mines.enumerated() {
            locations[index].hasMine = hasMine
            if hasMine {
                for neighbour in self.neighbour(of: Position(x: index % width, y: index / width)) {
                    let i = neighbour.y * width + neighbour.x
                    locations[i].numberOfMinesAround += 1
                }
            }
        }
        self.locations = locations

        let elapsed = CACurrentMediaTime() - now
        logger.info("\(self.numberOfMines) Mines placed in \(elapsed * 1000.0)ms")
    }

    public func multiRelease(at position: Position) {
        let location = self.location(at: position)

        var flags = 0
        var unknowns = 0
        for neighbour in self.neighbour(of: position) {
            if flagAt(x: neighbour.x, y: neighbour.y) == .flag {
                flags += 1
            } else {
                unknowns += 1
            }
        }

        // If we have correct number of flags to mines then clear the other
        // locations, otherwise if the number of unknown squares is the
        // same as the number of mines flag them all.
        var doClear: Bool = false
        if flags == location.numberOfMinesAround {
            doClear = true
        } else if autoFlag && unknowns == numberOfMines {
            doClear = false
        } else {
            return
        }

        for neighbour in self.neighbour(of: position) {
            let flag = flagAt(x: neighbour.x, y: neighbour.y)
            if doClear && flag != .flag {
                clearMine(at: neighbour)
            } else {
                changeFlag(to: .flag, at: neighbour)
            }
        }
    }

    public func clearMine(at position: Position) {
        if isExploded || isCompleted {
            return
        }

        // Place mines on first attempt to clear.
        if !isPlacedMines {
            logger.info("New game started at \(position)")
            placeMine(avoiding: position)
            isPlacedMines = true
        }

        let location = location(at: position)
        if location.isCleared || location.flag == .flag {
            return
        }

        logger.info("Clearing \(position)")

        // Failed if this contained a mine.
        if location.hasMine {
            logger.info("Exploded at \(position)")
            isExploded = true
            return
        }

        var locations = self.locations
        clearMinesRecursively(at: position, in: &locations)

        // Mark unmarked mines when won.
        let isCompleted = numberOfCleared == width * height - numberOfMines
        if isCompleted {
            logger.info("Game completed")
            for (index, location) in locations.enumerated() {
                if location.hasMine && location.flag != .flag {
                    locations[index].flag = .flag
                }
            }
            self.isCompleted = true
        }
        self.locations = locations
    }

    private func clearMinesRecursively(at position: Position, in locations: inout [Location]) {
        let index = position.y * width + position.x
        let location = locations[index]
        // Ignore if already cleared or flagged.
        if location.isCleared || location.flag == .flag {
            return
        }

        locations[index].isCleared = true
        numberOfCleared += 1
        if location.flag == .flag {
            numberOfFlagged -= 1
        }
        locations[index].flag = .none

        // Automatically clear locations around if no mines around.
        if location.numberOfMinesAround == 0 {
            for neighbour in neighbour(of: position) {
                clearMinesRecursively(at: neighbour, in: &locations)
            }
        }
    }
}
