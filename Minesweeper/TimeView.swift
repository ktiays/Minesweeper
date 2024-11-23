//
//  Created by ktiays on 2024/11/15.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI

struct TimeView: View {

    @State private var elapsedSeconds: Int = 0
    let isPaused: Bool

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var hours: String?
    @State private var minutes: String = "00"
    @State private var seconds: String = "00"
    
    init(isPaused: Bool = false) {
        self.isPaused = isPaused
    }
    
    @ViewBuilder
    private var colon: some View {
        VStack(spacing: 4) {
            Circle()
                .frame(width: 4, height: 4)
            Circle()
                .frame(width: 4, height: 4)
        }
        .padding(.trailing, 1)
    }

    var body: some View {
        HStack(spacing: 2) {
            if let hours {
                Text(hours)
                colon
            }
            Text(minutes)
            colon
            Text(seconds)
        }
        .font(.system(size: 20, weight: .bold, design: .rounded))
        .foregroundColor(.primary)
        .contentTransition(.numericText())
        .onReceive(timer) { _ in
            if isPaused { return }
            
            elapsedSeconds += 1
            withAnimation {
                updateTimeText()
            }
        }
    }

    private func updateTimeText() {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60

        if hours > 0 {
            self.hours = String(format: "%02d", hours)
        }
        self.minutes = String(format: "%02d", minutes)
        self.seconds = String(format: "%02d", seconds)
    }
}

#Preview {
    TimeView()
}
