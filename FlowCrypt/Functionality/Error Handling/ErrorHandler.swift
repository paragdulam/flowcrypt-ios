//
//  ErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 20/07/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import UIKit

extension UIViewController {
    @discardableResult
    func handleCommon(error: Error) -> Bool {
        let composedHandler = ComposedErrorHandler.shared
        let isErrorHandled = composedHandler.handle(error: error, for: self)

        if !isErrorHandled {
            Logger.nested("ERROR HANDLING").logInfo("ErrorHandler should be used for this error ***** \(error)")
        }

        return isErrorHandled
    }
}

// MARK: - ErrorHandler
protocol ErrorHandler {
    func handle(error: Error, for viewController: UIViewController) -> Bool
}

/// This Handler contains array of all possible handlers
private struct ComposedErrorHandler: ErrorHandler {
    static let shared: ComposedErrorHandler = ComposedErrorHandler(
        handlers: [
            KeyServiceErrorHandler(),
            BackupServiceErrorHandler(),
            CreateKeyErrorHandler()
        ]
    )

    let handlers: [ErrorHandler]

    func handle(error: Error, for viewController: UIViewController) -> Bool {
        let isErrorHandled = handlers.map { $0.handle(error: error, for: viewController) }

        // Error is handled by one of the handlers
        return isErrorHandled.contains(true)
    }
}

// MARK: - ERROR HANDLING
// TODO: - ERROR HANDLING
// https://github.com/FlowCrypt/flowcrypt-ios/issues/140

//protocol AppError {
//    var localizedDescription: String { get }
//}

// In case Errors should be handled differently for some cases
// func handle(error: Error, for viewController: UIViewController) -> Bool
// should be improved to use Presenter instead of UIViewController
// and Promise<Bool> as return type instead of Bool in case of callback or async handling

// ADD FALLBACK TO ERROR HANDLING

// MARK: - ERRORS

// GmailServiceError +
// BackupServiceError +
// KeyServiceError
// UserError
// SetupError
// InboxViewControllerContainerError
// HttpErr
// CoreError
// SessionCredentialsError
// ImapError
// AppErr (refactor before)
// KeyServiceError
// BackupServiceError
// ContactsError
// KeyInfoError
// BackupError
