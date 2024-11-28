//
//  Created by ktiays on 2024/11/15.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI

struct TimeView: View {

    @Binding var elapsedSeconds: Int
    let isPaused: Bool

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var hours: String? {
        let hours = elapsedSeconds / 3600
        if hours > 0 {
            return String(format: "%02d", hours)
        }
        return nil
    }
    private var minutes: String {
        .init(format: "%02d", (elapsedSeconds % 3600) / 60)
    }
    private var seconds: String {
        .init(format: "%02d", elapsedSeconds % 60)
    }
    
    init(seconds: Binding<Int>, isPaused: Bool = false) {
        _elapsedSeconds = seconds
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
            
            withAnimation {
                elapsedSeconds += 1
            }
        }
    }
}
