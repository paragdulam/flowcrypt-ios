//
//  HeaderNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class HeaderNode: CellNode {
    public struct Input {
        public let title: NSAttributedString
        public let subtitle: NSAttributedString?
        public let image: UIImage?
        public let imageSize: CGSize

        public init(title: NSAttributedString, subtitle: NSAttributedString?, image: UIImage?, imageSize: CGSize = CGSize(width: 24, height: 24)) {
            self.title = title
            self.subtitle = subtitle
            self.image = image
            self.imageSize = imageSize
        }
    }

    private let titleNode = ASTextNode2()
    private let subTitleNode = ASTextNode2()
    public private(set) var imageNode = ASImageNode()

    private let input: HeaderNode.Input
    private var onTap: (() -> Void)?

    public init(input: HeaderNode.Input, onTap: (() -> Void)?) {
        self.input = input
        self.onTap = onTap
        super.init()
        automaticallyManagesSubnodes = true

        titleNode.attributedText = input.title
        subTitleNode.attributedText = input.subtitle
        imageNode.image = input.image
        backgroundColor = .main

        imageNode.addTarget(self, action: #selector(onImageTap), forControlEvents: .touchUpInside)
    }

    @objc private func onImageTap() {
        onTap?()
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        imageNode.style.preferredSize = input.imageSize
        subTitleNode.style.flexGrow = 1
        subTitleNode.style.flexShrink = 1
        let subtitleSpec = ASStackLayoutSpec.horizontal().then {
            $0.children = [subTitleNode, imageNode]
            $0.alignItems = .center
        }
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 32, left: 16, bottom: 32, right: 16),
            child: ASStackLayoutSpec.vertical().then {
                $0.spacing = 8
                $0.children = [titleNode, subtitleSpec]
            }
        )
    }
}
