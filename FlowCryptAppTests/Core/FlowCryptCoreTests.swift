//
//  FlowCryptUITests.swift
//  FlowCryptUITests
//
//  Created by luke on 21/7/2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import XCTest
import Combine
@testable import FlowCrypt

class FlowCryptCoreTests: XCTestCase {
    var core: Core! = .shared
    private var cancellable = Set<AnyCancellable>()
    
    override func setUp() {
        let expectation = XCTestExpectation()
        core.startInBackgroundIfNotAlreadyRunning() {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    // the tests below

    func testVersions() throws {
        let r = try core.version()
        XCTAssertEqual(r.app_version, "iOS 0.2")
    }

    func testGenerateKey() throws {
        let r = try core.generateKey(passphrase: "some pass phrase test", variant: KeyVariant.curve25519, userIds: [UserId(email: "first@domain.com", name: "First")])
        XCTAssertNotNil(r.key.private)
        XCTAssertEqual(r.key.isFullyDecrypted, false)
        XCTAssertEqual(r.key.isFullyEncrypted, true)
        XCTAssertNotNil(r.key.private!.range(of: "-----BEGIN PGP PRIVATE KEY BLOCK-----"))
        XCTAssertNotNil(r.key.public.range(of: "-----BEGIN PGP PUBLIC KEY BLOCK-----"))
        XCTAssertEqual(r.key.ids.count, 2)
    }

    func testZxcvbnStrengthBarWeak() throws {
        let r = try core.zxcvbnStrengthBar(passPhrase: "nothing much")
        XCTAssertEqual(r.word.word, CoreRes.ZxcvbnStrengthBar.WordDetails.Word.weak)
        XCTAssertEqual(r.word.pass, false)
        XCTAssertEqual(r.word.color, CoreRes.ZxcvbnStrengthBar.WordDetails.Color.red)
        XCTAssertEqual(r.word.bar, 10)
        XCTAssertEqual(r.time, "less than a second")
    }

    func testZxcvbnStrengthBarStrong() throws {
        let r = try core.zxcvbnStrengthBar(passPhrase: "this one is seriously over the top strong pwd")
        XCTAssertEqual(r.word.word, CoreRes.ZxcvbnStrengthBar.WordDetails.Word.perfect)
        XCTAssertEqual(r.word.pass, true)
        XCTAssertEqual(r.word.color, CoreRes.ZxcvbnStrengthBar.WordDetails.Color.green)
        XCTAssertEqual(r.word.bar, 100)
        XCTAssertEqual(r.time, "millennia")
    }

    func testParseKeys() throws {
        let r = try core.parseKeys(armoredOrBinary: TestData.k0.pub.data(using: .utf8)! + [10] + TestData.k1.prv.data(using: .utf8)!)
        XCTAssertEqual(r.format, CoreRes.ParseKeys.Format.armored)
        XCTAssertEqual(r.keyDetails.count, 2)
        // k0 k is public
        let k0 = r.keyDetails[0]
        XCTAssertNil(k0.private)
        XCTAssertNil(k0.isFullyDecrypted)
        XCTAssertNil(k0.isFullyEncrypted)
        XCTAssertEqual(k0.longid, TestData.k0.longid)
        XCTAssertEqual(k0.lastModified, 1543925225)
        XCTAssertNil(k0.expiration)
        // k1 is private
        let k1 = r.keyDetails[1]
        XCTAssertNotNil(k1.private)
        XCTAssertEqual(k1.isFullyDecrypted, false)
        XCTAssertEqual(k1.isFullyEncrypted, true)
        XCTAssertEqual(k1.longid, TestData.k1.longid)
        XCTAssertEqual(k1.lastModified, 1563630809)
        XCTAssertNil(k1.expiration)
        // todo - could test user ids
    }

    func testDecryptKeyWithCorrectPassPhrase() throws {
        let decryptKeyRes = try core.decryptKey(armoredPrv: TestData.k0.prv, passphrase: TestData.k0.passphrase)
        XCTAssertNotNil(decryptKeyRes.decryptedKey)
        // make sure indeed decrypted
        let parseKeyRes = try core.parseKeys(armoredOrBinary: decryptKeyRes.decryptedKey.data(using: .utf8)!)
        XCTAssertEqual(parseKeyRes.keyDetails[0].isFullyDecrypted, true)
        XCTAssertEqual(parseKeyRes.keyDetails[0].isFullyEncrypted, false)
    }

    func testDecryptKeyWithWrongPassPhrase() {
        XCTAssertThrowsError(try core.decryptKey(armoredPrv: TestData.k0.prv, passphrase: "wrong"))
    }

    func testComposeEmailPlain() throws {
        let msg = SendableMsg(text: "this is the message", to: ["email@hello.com"], cc: [], bcc: [], from: "sender@hello.com", subject: "subj", replyToMimeMsg: nil, atts: [], pubKeys: nil)
        let expectation = XCTestExpectation()
        
        var mime: String = ""
        core.composeEmail(msg: msg, fmt: .plain, pubKeys: nil)
            .sinkFuture(
                receiveValue: { composeEmailRes in
                    mime = String(data: composeEmailRes.mimeEncoded, encoding: .utf8)!
                    expectation.fulfill()
                }, receiveError: {_ in }
            )
            .store(in: &cancellable)
        wait(for: [expectation], timeout: 3)
        XCTAssertNil(mime.range(of: "-----BEGIN PGP MESSAGE-----")) // not encrypted
        XCTAssertNotNil(mime.range(of: msg.text)) // plain text visible
        XCTAssertNotNil(mime.range(of: "Subject: \(msg.subject)")) // has mime Subject header
        XCTAssertNil(mime.range(of: "In-Reply-To")) // Not a reply
    }

    func testComposeEmailEncryptInline() throws {
        let msg = SendableMsg(text: "this is the message", to: ["email@hello.com"], cc: [], bcc: [], from: "sender@hello.com", subject: "subj", replyToMimeMsg: nil, atts: [], pubKeys: nil)
        let expectation = XCTestExpectation()
        
        var mime: String = ""
        core.composeEmail(msg: msg, fmt: .encryptInline, pubKeys: [TestData.k0.pub, TestData.k1.pub])
            .sinkFuture(
                receiveValue: { composeEmailRes in
                    mime = String(data: composeEmailRes.mimeEncoded, encoding: .utf8)!
                    expectation.fulfill()
                }, receiveError: {_ in }
            )
            .store(in: &cancellable)
        wait(for: [expectation], timeout: 3)
        XCTAssertNotNil(mime.range(of: "-----BEGIN PGP MESSAGE-----")) // encrypted
        XCTAssertNil(mime.range(of: msg.text)) // plain text not visible
        XCTAssertNotNil(mime.range(of: "Subject: \(msg.subject)")) // has mime Subject header
        XCTAssertNil(mime.range(of: "In-Reply-To")) // Not a reply
    }
    
    func testComposeEmailInlineWithAttachment() throws {
        
        let initialFileName = "data.txt"
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self))
            .path(forResource: "data", ofType: "txt")!)
        let fileData = try! Data(contentsOf: urlPath, options: .dataReadingMapped)
        
        let attachment = SendableMsg.Attachment(
            name: initialFileName, type: "text/plain",
            base64: fileData.base64EncodedString()
        )
        
        let msg = SendableMsg(
            text: "this is the message",
            to: ["email@hello.com"], cc: [], bcc: [],
            from: "sender@hello.com",
            subject: "subj", replyToMimeMsg: nil,
            atts: [attachment], pubKeys: nil
        )
        let expectation = XCTestExpectation()
        
        var mime: String = ""
        core.composeEmail(msg: msg, fmt: .encryptInline, pubKeys: [TestData.k0.pub, TestData.k1.pub])
            .sinkFuture(
                receiveValue: { composeEmailRes in
                    mime = String(data: composeEmailRes.mimeEncoded, encoding: .utf8)!
                    expectation.fulfill()
                }, receiveError: {_ in }
            )
            .store(in: &cancellable)
        wait(for: [expectation], timeout: 3)
        XCTAssertNil(mime.range(of: msg.text)) // text encrypted
        XCTAssertNotNil(mime.range(of: "Content-Type: application/pgp-encrypted")) // encrypted
        XCTAssertNotNil(mime.range(of: "name=\(attachment.name)")) // attachment
        XCTAssertNotNil(mime.range(of: "Subject: \(msg.subject)")) // has mime Subject header
    }

    func testEndToEnd() throws {
        let passphrase = "some pass phrase test"
        let email = "e2e@domain.com"
        let text = "this is the encrypted e2e content"
        let generateKeyRes = try core.generateKey(passphrase: passphrase, variant: KeyVariant.curve25519, userIds: [UserId(email: email, name: "End to end")])
        let k = generateKeyRes.key
        let msg = SendableMsg(text: text, to: [email], cc: [], bcc: [], from: email, subject: "e2e subj", replyToMimeMsg: nil, atts: [], pubKeys: nil)
        let expectation = XCTestExpectation()
        
        var mime: CoreRes.ComposeEmail?
        core.composeEmail(msg: msg, fmt: .encryptInline, pubKeys: [k.public])
            .sinkFuture(
                receiveValue: { composeEmailRes in
                    mime = composeEmailRes
                    expectation.fulfill()
                }, receiveError: {_ in }
            )
            .store(in: &cancellable)
        wait(for: [expectation], timeout: 3)
        let keys = [PrvKeyInfo(private: k.private!, longid: k.ids[0].longid, passphrase: passphrase, fingerprints: k.fingerprints)]
        let decrypted = try core.parseDecryptMsg(encrypted: mime?.mimeEncoded ?? Data(), keys: keys, msgPwd: nil, isEmail: true)
        XCTAssertEqual(decrypted.text, text)
        XCTAssertEqual(decrypted.replyType, CoreRes.ReplyType.encrypted)
        XCTAssertEqual(decrypted.blocks.count, 1)
        let b = decrypted.blocks[0]
        XCTAssertNil(b.keyDetails) // should only be present on pubkey blocks
        XCTAssertNil(b.decryptErr) // was supposed to be a success
        XCTAssertEqual(b.type, MsgBlock.BlockType.plainHtml)
        XCTAssertNotNil(b.content.range(of: text)) // original text contained within the formatted html block
    }

    func testDecryptErrMismatch() throws {
        let key = PrvKeyInfo(private: TestData.k0.prv, longid: TestData.k0.longid, passphrase: TestData.k0.passphrase, fingerprints: TestData.k0.fingerprints)
        let r = try core.parseDecryptMsg(encrypted: TestData.mismatchEncryptedMsg.data(using: .utf8)!, keys: [key], msgPwd: nil, isEmail: false)
        let decrypted = r
        XCTAssertEqual(decrypted.text, "")
        XCTAssertEqual(decrypted.replyType, CoreRes.ReplyType.plain) // replies to errors should be plain
        XCTAssertEqual(decrypted.blocks.count, 2)
        let contentBlock = decrypted.blocks[0]
        XCTAssertEqual(contentBlock.type, MsgBlock.BlockType.plainHtml)
        XCTAssertNotNil(contentBlock.content.range(of: "<body></body>")) // formatted content is empty
        let decryptErrBlock = decrypted.blocks[1]
        XCTAssertEqual(decryptErrBlock.type, MsgBlock.BlockType.decryptErr)
        XCTAssertNotNil(decryptErrBlock.decryptErr)
        let e = decryptErrBlock.decryptErr!
        XCTAssertEqual(e.error.type, MsgBlock.DecryptErr.ErrorType.keyMismatch)
    }
    
    func testEncryptFile() throws {
        // Given
        let initialFileName = "data.txt"
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self))
            .path(forResource: "data", ofType: "txt")!)
        let fileData = try! Data(contentsOf: urlPath, options: .dataReadingMapped)
        
        let passphrase = "some pass phrase test"
        let email = "e2e@domain.com"
        let generateKeyRes = try core.generateKey(
            passphrase: passphrase,
            variant: KeyVariant.curve25519,
            userIds: [UserId(email: email, name: "End to end")]
        )
        let k = generateKeyRes.key
        let keys = [
            PrvKeyInfo(
                private: k.private!,
                longid: k.ids[0].longid,
                passphrase: passphrase,
                fingerprints: k.fingerprints
            )
        ]
        
        // When
        let encrypted = try core.encryptFile(
            pubKeys: [k.public],
            fileData: fileData,
            name: initialFileName
        )
        let decrypted = try core.decryptFile(
            encrypted: encrypted.encryptedFile,
            keys: keys,
            msgPwd: nil
        )
        
        // Then
        XCTAssertTrue(decrypted.content == fileData)
        XCTAssertTrue(decrypted.content.toStr() == fileData.toStr())
        XCTAssertTrue(decrypted.name == initialFileName)
    }
    
    func testDecryptNotEncryptedFile() throws {
        // Given
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self))
            .path(forResource: "data", ofType: "txt")!)
        let fileData = try! Data(contentsOf: urlPath, options: .dataReadingMapped)
        
        let passphrase = "some pass phrase test"
        let email = "e2e@domain.com"
        let generateKeyRes = try core.generateKey(
            passphrase: passphrase,
            variant: KeyVariant.curve25519,
            userIds: [UserId(email: email, name: "End to end")]
        )
        let k = generateKeyRes.key
        let keys = [
            PrvKeyInfo(
                private: k.private!,
                longid: k.ids[0].longid,
                passphrase: passphrase,
                fingerprints: k.fingerprints
            )
        ]
        
        // When
        do {
            _ = try self.core.decryptFile(
                encrypted: fileData,
                keys: keys,
                msgPwd: nil
            )
            XCTFail("Should have thrown above")
        } catch let CoreError.format(message) {
            // Then
            XCTAssertNotNil(message.range(of: "Error: Error during parsing"))
        }
    }
    
    func testDecryptWithNoKeys() throws {
        // Given
        let initialFileName = "data.txt"
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self))
            .path(forResource: "data", ofType: "txt")!)
        let fileData = try! Data(contentsOf: urlPath, options: .dataReadingMapped)
        
        let passphrase = "some pass phrase test"
        let email = "e2e@domain.com"
        let generateKeyRes = try core.generateKey(
            passphrase: passphrase,
            variant: KeyVariant.curve25519,
            userIds: [UserId(email: email, name: "End to end")]
        )
        let k = generateKeyRes.key
        
        // When
        do {
            let encrypted = try core.encryptFile(
                pubKeys: [k.public],
                fileData: fileData,
                name: initialFileName
            )
            _ = try self.core.decryptFile(
                encrypted: encrypted.encryptedFile,
                keys: [],
                msgPwd: nil
            )
            XCTFail("Should have thrown above")
        } catch let CoreError.keyMismatch(message) {
            // Then
            XCTAssertNotNil(message.range(of: "Missing appropriate key"))
        }
    }
    
    func testDecryptEncryptedFile() throws {
        // Given
        let initialFileName = "data.txt"
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self))
            .path(forResource: "data", ofType: "txt")!)
        let fileData = try! Data(contentsOf: urlPath, options: .dataReadingMapped)
        
        let passphrase = "some pass phrase test"
        let email = "e2e@domain.com"
        let generateKeyRes = try core.generateKey(
            passphrase: passphrase,
            variant: KeyVariant.curve25519,
            userIds: [UserId(email: email, name: "End to end")]
        )
        let k = generateKeyRes.key
        let keys = [
            PrvKeyInfo(
                private: k.private!,
                longid: k.ids[0].longid,
                passphrase: passphrase,
                fingerprints: k.fingerprints
            )
        ]
        
        // When
        do {
            let encrypted = try core.encryptFile(
                pubKeys: [k.public],
                fileData: fileData,
                name: initialFileName
            )
            let decrypted = try self.core.decryptFile(
                encrypted: encrypted.encryptedFile,
                keys: keys,
                msgPwd: nil
            )
            // Then
            XCTAssertEqual(decrypted.name, initialFileName)
            XCTAssertEqual(decrypted.content.count, fileData.count)
        } catch {
            XCTFail("Core file decryption should not fail")
        }
    }
    
    func testException() throws {
        do {
            _ = try core.decryptKey(armoredPrv: "not really a key", passphrase: "whatnot")
            XCTFail("Should have thrown above")
        } catch let CoreError.exception(message) {
            XCTAssertNotNil(message.range(of: "Error: Misformed armored text"))
        }
    }
}
