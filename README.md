# SweepMines

A modern implementation of the classic Minesweeper game for iOS and macOS (via Mac Catalyst), built with Swift.

## Features

- **Multiple Difficulty Levels**:

  - Beginner: 9×9 grid with 10 mines
  - Intermediate: 16×16 grid with 40 mines (macOS) / 9×16 grid with 30 mines (iOS)
  - Expert: 18×32 grid with 99 mines
  - Custom: Create your own game with customizable width, height, and mine count

- **Intuitive Touch Controls**:

  - Tap to reveal a cell
  - Long-press or secondary click to flag a cell
  - Gesture-based flag menu for quick marking
  - Multi-cell clearing when adjacent numbers are satisfied

- **Modern UI Design**:

  - Smooth animations and transitions
  - Haptic feedback
  - Optimized for both iOS and macOS platforms
  - Dynamically adapting layouts
  - Confetti animation on winning

- **Game Features**:
  - Timer to track your progress
  - Mine counter to show remaining mines
  - Game state preservation
  - First-tap protection (you'll never hit a mine on your first move)

## Platform Support

SweepMines is optimized for both iOS and macOS:

- **iOS**: Full support for touch gestures, haptic feedback, and adaptive layouts for various iPhone and iPad models.
- **macOS**: Enhanced via Mac Catalyst with native toolbar integration, menu support, and keyboard/mouse interaction.

The application provides a seamless experience across all Apple devices with exceptional performance, even on larger grid sizes, thanks to optimized rendering and animation techniques.

## Requirements

- iOS 16.0+ / macOS 13.0+
- Xcode 15.0+

## License

Copyright © 2025 ktiays. All rights reserved.
