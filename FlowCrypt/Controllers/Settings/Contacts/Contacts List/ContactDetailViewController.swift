//
//  ContactDetailViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

/**
 * View controller which shows details about a contact and the public key recorded for it
 * - User can be redirected here from settings *ContactsListViewController* by tapping on a particular contact
 */
final class ContactDetailViewController: TableNodeViewController {
    typealias ContactDetailAction = (Action) -> Void

    enum Action {
        case delete(_ contact: Contact)
    }

    private let decorator: ContactDetailDecoratorType
    private let contact: Contact
    private let action: ContactDetailAction?

    init(
        decorator: ContactDetailDecoratorType = ContactDetailDecorator(),
        contact: Contact,
        action: ContactDetailAction?
    ) {
        self.decorator = decorator
        self.contact = contact
        self.action = action
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        node.delegate = self
        node.dataSource = self
        title = decorator.title
        setupNavigationBarItems()
    }

    private func setupNavigationBarItems() {
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                .init(image: UIImage(named: "share"), action: (self, #selector(handleSaveAction))),
                .init(image: UIImage(named: "copy"), action: (self, #selector(handleCopyAction))),
                .init(image: UIImage(named: "trash"), action: (self, #selector(handleRemoveAction)))
            ]
        )
    }
}

extension ContactDetailViewController {
    @objc private final func handleSaveAction() {
        let vc = UIActivityViewController(
            activityItems: [contact.pubKey],
            applicationActivities: nil
        )
        present(vc, animated: true, completion: nil)
    }

    @objc private final func handleCopyAction() {
        UIPasteboard.general.string = contact.pubKey
        showToast("contact_detail_copy".localized)
    }

    @objc private final func handleRemoveAction() {
        navigationController?.popViewController(animated: true) { [weak self] in
            guard let self = self else { return }
            self.action?(.delete(self.contact))
        }
    }
}

extension ContactDetailViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        { [weak self] in
            guard let self = self else { return ASCellNode() }
            return ContactDetailNode(input: self.decorator.nodeInput(with: self.contact))
        }
    }
}
