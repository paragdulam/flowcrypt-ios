//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

final class BackendApi {
    static let shared: BackendApi = BackendApi()

    private init() {}

    private static func url(endpoint: String) -> String {
        "https://flowcrypt.com/api/\(endpoint)"
    }

    private static func normalize(_ email: String) -> String {
        email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
