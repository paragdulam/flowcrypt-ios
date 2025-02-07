//
//  KeyTextCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class KeyTextCellNode: CellNode {
    private let textNode = ASTextNode2()
    private let selectedNode = ASDisplayNode()

    private let insets: UIEdgeInsets

    public init(
        title: NSAttributedString,
        insets: UIEdgeInsets
    ) {
        self.insets = insets
        super.init()
        textNode.attributedText = title
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: insets,
            child: textNode
        )
    }
}
