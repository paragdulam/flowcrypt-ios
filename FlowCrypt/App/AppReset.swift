//
//  AppReset.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum AppReset: String {
    case reset = "--reset"

    static func resetKeychain() {
        let secClasses = [
            kSecClassGenericPassword as String,
            kSecClassInternetPassword as String,
            kSecClassCertificate as String,
            kSecClassKey as String,
            kSecClassIdentity as String
        ]
        for secClass in secClasses {
            let query = [kSecClass as String: secClass]
            SecItemDelete(query as CFDictionary)
        }
    }

    static func resetUserDefaults() {
        guard let identifier = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: identifier)
    }
}
