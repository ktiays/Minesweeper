//
//  Created by ktiays on 2024/11/27.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI
import UIKit

final class AlertViewController: UIViewController {

    let dimmingView: UIView = .init()
    private(set) lazy var contentView: _UIHostingView<AlertContentView> = .init(
        rootView: .init(
            title: title,
            message: message,
            content: content
        )
    )

    let message: String?
    private let content: AnyView

    init<V>(title: String? = nil, message: String? = nil, @ViewBuilder content: () -> V) where V: View {
        self.message = message
        self.content = AnyView(content())
        super.init(nibName: nil, bundle: nil)
        self.title = title
        self.transitioningDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var modalPresentationStyle: UIModalPresentationStyle {
        get { .overCurrentContext }
        set {}
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dimmingView.backgroundColor = .black
        view.addSubview(dimmingView)
        view.addSubview(contentView)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        layout(in: view.bounds)
    }

    func layout(in bounds: CGRect) {
        dimmingView.frame = bounds

        let contentSize = contentView.sizeThatFits(bounds.insetBy(dx: 56, dy: 56).size)
        contentView.frame = .init(
            x: (bounds.width - contentSize.width) / 2,
            y: (bounds.height - contentSize.height) / 2,
            width: contentSize.width,
            height: contentSize.height
        )
    }
}

extension AlertViewController: UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        AlertTransitionAnimator(isPresenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        AlertTransitionAnimator(isPresenting: false)
    }
}

struct AlertContentView: View {

    let title: String?
    let message: String?
    private let content: AnyView

    init(title: String? = nil, message: String? = nil, content: AnyView) {
        self.title = title
        self.message = message
        self.content = content
    }

    var body: some View {
        VStack {
            VStack(spacing: 12) {
                if let title {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .padding(.top, 8)
                }
                if let message {
                    Text(message)
                        .font(.system(size: 14, design: .rounded))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            HStack {
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())]) {
                    content
                }
            }
            .buttonStyle(AlertButtonStyle())
            .padding(12)
        }
        .background(.thinMaterial)
        .background {
            Rectangle()
                .fill(.boardBackground)
                .opacity(0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke()
                .foregroundStyle(Color(uiColor: .separator))
        }
    }
}

struct AlertButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let isDestructive = configuration.role == .destructive
        configuration.label
            .foregroundStyle(isDestructive ? .white : .accent)
            .font(
                .system(
                    size: 17,
                    weight: isDestructive ? .semibold : .regular,
                    design: .rounded
                )
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background {
                if isDestructive {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .foregroundStyle(.accent)
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke()
                        .foregroundStyle(.accent)
                }
            }
            .opacity(configuration.isPressed ? 0.3 : 1)
            .contentShape(Rectangle())
    }
}

#Preview {
    AlertViewController(title: "Alert Title", message: "Alert message") {
        Button("Cancel", role: .cancel) {

        }
        Button("Confirm", role: .destructive) {

        }
    }
}
