//
//  Created by ktiays on 2024/3/31.
//  Copyright (c) 2024 Helixform. All rights reserved.
//

import SwiftSignal
import SwiftUI
import SwiftUISignal

private struct _EqutableAnyView: View, Equatable {

    private let content: AnyView

    init<Content>(_ content: Content) where Content: View {
        self.content = .init(content)
    }

    var body: some View {
        content
    }

    static func == (lhs: _EqutableAnyView, rhs: _EqutableAnyView) -> Bool {
        false
    }
}

private struct _SignalCompatibleBuilderView<Content>: View where Content: View {

    @ObservedObject private var content: ObservedComputed<_EqutableAnyView>

    @inlinable
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = .init {
            _EqutableAnyView(content())
        }
    }

    var body: some View {
        content()
    }
}

#if canImport(UIKit)
typealias PlatformHostingView = _UIHostingView
#else
typealias PlatformHostingView = NSHostingView
#endif

final class BuilderHostingView: PlatformHostingView<AnyView> {

    init<Content>(@ViewBuilder content: @escaping () -> Content) where Content: View {
        super.init(rootView: AnyView(_SignalCompatibleBuilderView(content: content)))
    }

    required init(rootView: AnyView) {
        super.init(rootView: rootView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not supported")
    }
}
