//
//  KeyDetailInfoViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class KeyDetailInfoViewController: TableNodeViewController {
    enum Parts: Int, CaseIterable {
        case keyWord, fingerptint, longId, date, users, separator

        var isSeparator: Bool {
            guard case .separator = self else { return false }
            return true
        }
    }

    private let decorator: KeyDetailInfoViewDecoratorType
    private let key: KeyDetails

    init(
        key: KeyDetails,
        decorator: KeyDetailInfoViewDecoratorType = KeyDetailInfoViewDecorator()
    ) {
        self.key = key
        self.decorator = decorator
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "key_settings_detail_public".localized

        node.delegate = self
        node.dataSource = self
        node.reloadData()
    }
}

extension KeyDetailInfoViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in _: ASTableNode) -> Int {
        key.ids.count
    }

    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        { [weak self] in
            guard let self = self,
                let part = Parts(rawValue: indexPath.row),
                let keyId = self.key.ids[safe: indexPath.section]
            else {
                return ASCellNode()
            }

            let title = self.decorator.attributedTitle(
                for: part,
                keyId: keyId,
                date: self.key.created.toDate(),
                user: self.key.users.joined(separator: " ")
            )

            if part.isSeparator {
                let isLastSection = indexPath.section == self.key.ids.count - 1
                let dividerHeight: CGFloat = isLastSection ? 0 : 1
                return DividerCellNode(
                    inset: self.decorator.dividerInsets,
                    height: dividerHeight
                )
            } else {
                return KeyTextCellNode(
                    title: title,
                    insets: self.decorator.insets
                )
            }
        }
    }
}
