//
//  Created by ktiays on 2024/11/27.
//  Copyright (c) 2024 ktiays. All rights reserved.
//

import SwiftUI
import UIKit

final class AlertViewController: UIViewController {

    let dimmingView: UIView = .init()
    private lazy var contentViewController: UIHostingController<AlertContentView> = .init(
        rootView: .init(
            title: title,
            message: message,
            content: content,
            customMode: customMode
        )
    )
    var contentView: UIView {
        contentViewController.view
    }
    var customMode: Bool = false

    let message: String?
    private let content: AnyView

    init<V>(title: String? = nil, message: String? = nil, @ViewBuilder content: () -> V) where V: View {
        self.message = message
        self.content = AnyView(content())
        super.init(nibName: nil, bundle: nil)
        self.title = title
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dimmingView.backgroundColor = .black
        contentView.backgroundColor = .clear
        view.addSubview(dimmingView)
        addChild(contentViewController)
        view.addSubview(contentView)
        contentViewController.didMove(toParent: self)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimmingViewTap(_:)))
        dimmingView.addGestureRecognizer(tapGesture)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        layout(in: view.bounds)
    }

    func layout(in bounds: CGRect) {
        dimmingView.frame = bounds
        
        let contentTransform = contentView.transform
        contentView.transform = .identity
        let maxWidth: CGFloat = 300
        var containerSize = bounds.insetBy(dx: 56, dy: 56).size
        containerSize.width = min(containerSize.width, maxWidth)
        let contentSize = contentView.sizeThatFits(containerSize)
        contentView.frame = .init(
            x: (bounds.width - contentSize.width) / 2,
            y: (bounds.height - contentSize.height) / 2,
            width: contentSize.width,
            height: contentSize.height
        )
        contentView.transform = contentTransform
    }
    
    @objc
    private func handleDimmingViewTap(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
}

extension AlertViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        AlertTransitionAnimator(isPresenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        AlertTransitionAnimator(isPresenting: false)
    }

    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        AlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

struct AlertContentView: View {

    let title: String?
    let message: String?
    private let content: AnyView
    private let customMode: Bool

    init(title: String? = nil, message: String? = nil, content: AnyView, customMode: Bool) {
        self.title = title
        self.message = message
        self.content = content
        self.customMode = customMode
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
                if customMode {
                    content
                } else {
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())]) {
                        content
                    }
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
