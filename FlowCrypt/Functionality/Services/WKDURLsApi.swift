//
//  WKDURLsService.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 23.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import CryptoKit
import FlowCryptCommon
import Promises

protocol WKDURLsApiType {
    func lookupEmail(_ email: String) -> Promise<[KeyDetails]>
}

class WKDURLsApi: WKDURLsApiType {

    private enum Constants {
        static let lookupEmailRequestTimeout: TimeInterval = 4
    }

    private let wkdURLsConstructor: WKDURLsConstructorType
    private let core: Core

    init(
        wkdURLsConstructor: WKDURLsConstructorType = WKDURLsConstructor(),
        core: Core = Core.shared
    ) {
        self.wkdURLsConstructor = wkdURLsConstructor
        self.core = core
    }

    func lookupEmail(_ email: String) -> Promise<[KeyDetails]> {
        Promise<[KeyDetails]> { [weak self] resolve, _ in
            guard let self = self else { return }
            let response = try awaitPromise(self.rawLookupEmail(email))
            guard let safeResponse = response else {
                resolve([])
                return
            }
            let pubKeys = safeResponse.keyDetails
                    .filter { !$0.users.filter { $0.contains(email) }.isEmpty }
            resolve(pubKeys)
        }
        .timeout(Constants.lookupEmailRequestTimeout)
        .recoverFromTimeOut(result: [])
    }

    func rawLookupEmail(_ email: String) -> Promise<CoreRes.ParseKeys?> {
        guard !Configuration.publicEmailProviderDomains.contains(email.recipientDomain ?? ""),
              let advancedUrlConstructorResult = wkdURLsConstructor.construct(from: email, mode: .advanced),
              let directUrlConstructorResult = wkdURLsConstructor.construct(from: email, mode: .direct)
               else {
            return Promise { resolve, _ in
                resolve(nil)
            }
        }

        return Promise<CoreRes.ParseKeys?> { [weak self] resolve, _ in
            guard let self = self else { return }
            var response: (hasPolicy: Bool, key: Data?)?
            response = try awaitPromise(
                self.urlLookup(
                    advancedUrlConstructorResult.urlString,
                    userPart: advancedUrlConstructorResult.userPart
                )
            )
            if response?.hasPolicy == true && response?.key == nil {
                resolve(nil)
                return
            }

            if response?.key == nil {
                response = try awaitPromise(
                    self.urlLookup(
                        directUrlConstructorResult.urlString,
                        userPart: directUrlConstructorResult.userPart
                    )
                )
                if response?.key == nil {
                    resolve(nil)
                    return
                }
            }
            guard let keyData = response?.key else {
                resolve(nil)
                return
            }
            resolve(try? self.core.parseKeys(armoredOrBinary: keyData))
        }
    }
}
extension WKDURLsApi {

    private func urlLookup(_ baseUrlString: String, userPart: String) -> Promise<(hasPolicy: Bool, key: Data?)> {

        let policyRequest = URLRequest.urlRequest(
            with: "\(baseUrlString)/policy",
            method: .get,
            body: nil
        )

        let publicKeyRequest = URLRequest.urlRequest(
            with: "\(baseUrlString)/\(userPart)",
            method: .get,
            body: nil
        )

        return Promise<(hasPolicy: Bool, key: Data?)> { resolve, _ in
            do {
                _ = try awaitPromise(URLSession.shared.call(policyRequest))
            } catch {
                Logger.nested("WKDURLsService").logInfo("Failed to load \(baseUrlString)/policy with error \(error)")
                resolve((false, nil))
            }
            let publicKeyResponse = try awaitPromise(URLSession.shared.call(publicKeyRequest, tolerateStatus: [404]))
            if !publicKeyResponse.data.toStr().isEmpty {
                Logger.nested("WKDURLsService").logInfo("Loaded WKD url \(baseUrlString)/\(userPart) and will try to extract Public Keys")
            }
            if publicKeyResponse.status == 404 {
                resolve((true, nil))
            }
            resolve((true, publicKeyResponse.data))
        }
    }
}
