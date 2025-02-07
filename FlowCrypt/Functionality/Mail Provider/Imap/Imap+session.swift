//
//  Imap+session.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import Foundation
import Promises

extension Imap {

    func setupSession() {
        guard
            let imapSession = dataService.imapSession(),
            let smtpSession = dataService.smtpSession()
        else { return }
        logger.logInfo("Create new imap and smtp session")

        createNewConnection(
            imapSession: imapSession,
            smtpSession: smtpSession
        )
    }

    private func createNewConnection(imapSession: IMAPSession?, smtpSession: SMTPSession?) {
        if let imap = imapSession {
            logger.logInfo("Creating a new IMAP session")
            let newImapSession = MCOIMAPSession(session: imap)
            imapSess = newImapSession
                .log()
        }

        if let smtp = smtpSession {
            logger.logInfo("Creating a new SMTP session")
            let newSmtpSession = MCOSMTPSession(session: smtp)
            smtpSess = newSmtpSession
                .log()
        }
    }

    func connectSmtp(session: SMTPSession) -> Promise<Void> {
        Promise { resolve, reject in
            MCOSMTPSession(session: session)
                .log()
                .loginOperation()?
                .start { error in
                    guard let error = error else { resolve(()); return }
                    reject(AppErr.unexpected("Can't establish SMTP Connection.\n\(error.localizedDescription)"))
                }
        }
    }

    func connectImap(session: IMAPSession) -> Promise<Void> {
         Promise { resolve, reject in
            MCOIMAPSession(session: session)
                .log()
                .connectOperation()?
                .start { [weak self] error in
                    guard let error = error else { resolve(()); return }
                    let message = "Can't establish IMAP Connection.\n\(error.localizedDescription)"
                    self?.logger.logError(message)
                    reject(AppErr.unexpected(message))
                }
        }
    }

    func disconnect() {
        let start = Trace(id: "Imap disconnect")
        imapSess?.disconnectOperation().start { [weak self] error in
            if let error = error {
                self?.logger.logError("disconnect with \(error)")
            } else {
                self?.logger.logInfo("disconnect with duration \(start.finish())")
            }
        }
        imapSess = nil
        smtpSess = nil // smtp session has no disconnect method
    }
}

extension MCOIMAPSession {
    func log() -> Self {
        connectionLogger = { _, type, data in
            guard let data = data, let string = String(data: data, encoding: .utf8) else { return }
            Logger.nested("IMAP").logInfo("\(type):\(string)")
        }
        return self
    }
}

extension MCOSMTPSession {
    func log() -> Self {
        connectionLogger = { _, type, data in
            guard let data = data, let string = String(data: data, encoding: .utf8) else { return }
            Logger.nested("SMTP").logInfo("\(type):\(string)")
        }
        return self
    }
}
