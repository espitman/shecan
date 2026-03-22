import Foundation

enum ShecanHelperConstants {
    static let machServiceName = "ir.shecan.desktop.helper"
    static let appBundleIdentifier = "ir.shecan.desktop"
    static let helperBundleIdentifier = "ir.shecan.desktop.helper"
    static let appRequirement = "identifier \"ir.shecan.desktop\""
    static let helperRequirement = "identifier \"ir.shecan.desktop.helper\""
}

@objc protocol ShecanPrivilegedHelperProtocol {
    func setDNSServers(
        forService service: String,
        servers: [String],
        withReply reply: @escaping (Bool, String?) -> Void
    )

    func restoreAutomaticDNS(
        forService service: String,
        withReply reply: @escaping (Bool, String?) -> Void
    )
}
