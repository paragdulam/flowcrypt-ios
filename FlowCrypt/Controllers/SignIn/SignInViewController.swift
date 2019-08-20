//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import GoogleSignIn
import Promises

class SignInViewController: BaseViewController {

    @IBOutlet weak var signInWithGmailButton: UIButton!
    @IBOutlet weak var signInWithOutlookButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        signInWithGmailButton.setViewBorder(1.0, borderColor: UIColor.lightGray, cornerRadius: 5.0)
        signInWithOutlookButton.setViewBorder(1.0, borderColor: UIColor.lightGray, cornerRadius: 5.0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    // MARK: - Events
    @IBAction func signInWithGmailButtonPressed(_ sender: Any) {
        async({ try await(GoogleApi.instance.signIn(viewController: self)) }, then: { [weak self] user in
            self?.performSegue(withIdentifier: "RecoverSegue", sender: nil)
        })
    }

    @IBAction func signInWithOutlookButtonPressed(_ sender: Any) {
        showToast("Outlook sign in not implemented yet")
        // below for debugging
        do {
            let start = DispatchTime.now()
//            let decrypted = try Core.decryptKey(armoredPrv: TestData.k3rsa4096.prv, passphrase: TestData.k3rsa4096.passphrase)
            let keys = [PrvKeyInfo(private: TestData.k3rsa4096.prv, longid: TestData.k3rsa4096.longid, passphrase: TestData.k3rsa4096.passphrase)]
            let decrypted = try Core.parseDecryptMsg(encrypted: TestData.matchingEncryptedMsg.data(using: .utf8)!, keys: keys, msgPwd: nil, isEmail: false)
            print(decrypted)
            print("decrypted \(start.millisecondsSince())")
//            print("text: \(decrypted.text)")
        } catch Core.Error.exception {
            print("catch exception")
//            print(msg)
        } catch {
            print("catch generic")
            print(error)
        }

    }

}
