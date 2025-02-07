//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

/**
 * Sign in controller
 * - User can sign in with:
 * - Gmail
 * - Outlook (not implemented yet)
 * - Other email provider (*SetupImapViewController*)
 * - User can also check privacy, terms and security links via *WebViewController*
 */
final class SignInViewController: TableNodeViewController {

    enum AppLinks: String, CaseIterable {
        case privacy, terms, security
    }

    enum Parts: Int, CaseIterable {
        case links, logo, description, gmail, outlook, other
    }

    private let globalRouter: GlobalRouterType
    private let core: Core
    private let decorator: SignInViewDecoratorType

    private lazy var logger = Logger.nested(Self.self)

    init(
        globalRouter: GlobalRouterType = GlobalRouter(),
        core: Core = Core.shared,
        decorator: SignInViewDecoratorType = SignInViewDecorator()
    ) {
        self.globalRouter = globalRouter
        self.core = core
        self.decorator = decorator

        super.init(node: TableNode())
        node.delegate = self
        node.dataSource = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    private func setup() {
        node.view.separatorStyle = .none
        node.view.alwaysBounceVertical = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension SignInViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let imageHeight = tableNode.bounds.size.height * 0.2

        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .links:
                return LinkButtonNode(SignInViewController.AppLinks.allCases) { [weak self] identifier in
                    guard let appLink = AppLinks(rawValue: identifier) else { return }
                    self?.handle(option: appLink)
                }
            case .logo:
                return SignInImageNode(self.decorator.logo, height: imageHeight)
            case .description:
                return SignInDescriptionNode(self.decorator.description)
            case .gmail:
                return SigninButtonNode(.gmail) { [weak self] in
                    self?.signInWithGmail()
                }
            case .outlook:
                return SigninButtonNode(.outlook) { [weak self] in
                    self?.signInWithOutlook()
                }
            case .other:
                let otherProviderInput = SigninButtonNode.Input(
                    title: "sign_in_other".localized.attributed(.medium(17), color: .mainTextColor),
                    image: UIImage(named: "email_icn")?.tinted(.mainTextColor)
                )
                return SigninButtonNode(input: otherProviderInput) { [weak self] in
                    self?.proceedToOtherProvider()
                }
            }
        }
    }
}

// MARK: - Events

extension SignInViewController {
    private func signInWithGmail() {
        globalRouter.signIn(with: .gmailLogin(self))
    }

    private func signInWithOutlook() {
        showToast("Outlook sign in not implemented yet")
    }

    private func proceedToOtherProvider() {
        let setupViewController = SetupImapViewController()
        navigationController?.pushViewController(setupViewController, animated: true)
    }

    private func handle(option: SignInViewController.AppLinks) {
        guard let url = option.url else { assertionFailure("Issue in provided url"); return }
        present(WebViewController(url: url), animated: true, completion: nil)
    }
}
