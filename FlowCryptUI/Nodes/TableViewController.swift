//
//  TableViewController.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 18.10.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

open class TableNodeViewController: ASDKViewController<TableNode> {
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        node.reloadData()
    }
}
