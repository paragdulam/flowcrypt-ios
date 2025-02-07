//
//  User.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct User: Codable, Equatable {
    let email: String
    let name: String
    let isActive: Bool
}
