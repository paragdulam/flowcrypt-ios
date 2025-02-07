//
//  KeyDataStorageService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation

final class KeyDataStorage {
    private lazy var logger = Logger.nested(Self.self)

    private let encryptedStorage: EncryptedStorageType

    init(
        encryptedStorage: EncryptedStorageType = EncryptedStorage()
    ) {
        self.encryptedStorage = encryptedStorage
    }
}

extension KeyDataStorage: KeyStorageType {
    func updateKeys(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) {
        encryptedStorage.updateKeys(keyDetails: keyDetails, passPhrase: passPhrase, source: source, for: email)
    }

    func publicKey() -> String? {
        encryptedStorage.publicKey()
    }

    func keysInfo() -> [KeyInfo] {
        encryptedStorage.keysInfo()
    }

    func addKeys(keyDetails: [KeyDetails], passPhrase: String?, source: KeySource, for email: String) {
        encryptedStorage.addKeys(keyDetails: keyDetails, passPhrase: passPhrase, source: source, for: email)
    }
}
