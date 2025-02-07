//
//  NavigationBarActionButton.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/23/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

public final class NavigationBarActionButton: UIBarButtonItem {
    private enum Constants {
        static let buttonSize = CGSize(width: 44, height: 44)
    }

    private var onAction: (() -> Void)?

    public convenience init(_ image: UIImage?, action: (() -> Void)?, accessibilityIdentifier: String? = nil) {
        self.init()
        onAction = action
        customView = LeftAlignedIconButton(type: .system).with {
            $0.setImage(image, for: .normal)
            $0.frame.size = Constants.buttonSize
            $0.addTarget(self, action: #selector(tap), for: .touchUpInside)
            $0.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    @objc private func tap() {
        onAction?()
    }
}

private final class LeftAlignedIconButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        contentHorizontalAlignment = .left
        let availableSpace = bounds.inset(by: contentEdgeInsets)
        let availableWidth = availableSpace.width - imageEdgeInsets.right - (imageView?.frame.width ?? 0) - (titleLabel?.frame.width ?? 0)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: availableWidth / 2, bottom: 0, right: 0)
    }
}
