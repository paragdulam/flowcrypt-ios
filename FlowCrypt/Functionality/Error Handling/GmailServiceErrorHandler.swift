//
//  GmailServiceErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

struct GmailServiceErrorHandler: ErrorHandler {
    func handle(error: Error, for viewController: UIViewController) -> Bool {
        let errorMessage: String?

        switch error {
        case let gmailError as GmailServiceError:
            switch gmailError {
            case .failedToParseData:
                errorMessage = "Failed to parse Gmail API Response"
            case .messageEncode:
                errorMessage = "Failed to encode message"
            case .missedMessageInfo(let context):
                errorMessage = "Failed to parse Gmail API Response. Missed message \(context)"
            case .missedMessagePayload:
                errorMessage = "Failed to parse Gmail API Response. Missed message payload"
            case .providerError(let error):
                errorMessage = "Provider error \(error)"
            case .missedBackupQuery:
                errorMessage = "Failed to get backup search query"
            }
        default:
            errorMessage = nil
        }

        guard let message = errorMessage else { return false }

        viewController.showAlert(message: message.localized)

        return true
    }
}
