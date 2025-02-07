//
//  MessageSubjectNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class MessageSubjectNode: CellNode {
    private let textNode = ASTextNode2()
    private let timeNode = ASTextNode2()

    public init(_ text: NSAttributedString?, time: NSAttributedString?) {
        super.init()
        textNode.attributedText = text
        timeNode.attributedText = time
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        textNode.style.flexGrow = 1.0
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8),
            child: ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 8,
                justifyContent: .start,
                alignItems: .center,
                children: [textNode, timeNode]
            )
        )
    }
}
