import Foundation
import Security
import ServiceManagement

enum PrivilegedHelperClientError: LocalizedError {
    case installationFailed(String)
    case connectionFailed(String)
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .installationFailed(let message):
            return message
        case .connectionFailed(let message):
            return message
        case .commandFailed(let message):
            return message
        }
    }
}

final class PrivilegedHelperClient {
    static let shared = PrivilegedHelperClient()

    private var connection: NSXPCConnection?

    func setDNSServers(serviceName: String, servers: [String]) throws {
        try runCommand { proxy, reply in
            proxy.setDNSServers(forService: serviceName, servers: servers, withReply: reply)
        }
    }

    func restoreAutomaticDNS(serviceName: String) throws {
        try runCommand { proxy, reply in
            proxy.restoreAutomaticDNS(forService: serviceName, withReply: reply)
        }
    }

    private func runCommand(
        invocation: (ShecanPrivilegedHelperProtocol, @escaping (Bool, String?) -> Void) -> Void
    ) throws {
        if !isHelperInstalled {
            try installHelper()
        }

        let semaphore = DispatchSemaphore(value: 0)
        var response: Result<Void, Error> = .failure(PrivilegedHelperClientError.connectionFailed("The helper did not respond."))
        let proxy = try helperProxy {
            response = .failure(PrivilegedHelperClientError.connectionFailed($0.localizedDescription))
            semaphore.signal()
        }

        invocation(proxy) { success, message in
            if success {
                response = .success(())
            } else {
                response = .failure(PrivilegedHelperClientError.commandFailed(message ?? "The privileged command failed."))
            }
            semaphore.signal()
        }

        semaphore.wait()
        _ = try response.get()
    }

    private var isHelperInstalled: Bool {
        FileManager.default.fileExists(atPath: "/Library/PrivilegedHelperTools/\(ShecanHelperConstants.machServiceName)")
    }

    private func installHelper() throws {
        var authRef: AuthorizationRef?
        let createStatus = AuthorizationCreate(nil, nil, AuthorizationFlags(), &authRef)
        guard createStatus == errAuthorizationSuccess, let authRef else {
            throw PrivilegedHelperClientError.installationFailed(message(for: createStatus))
        }
        defer {
            AuthorizationFree(authRef, AuthorizationFlags())
        }

        var authItem = AuthorizationItem(
            name: kSMRightBlessPrivilegedHelper,
            valueLength: 0,
            value: nil,
            flags: 0
        )
        var authRights = AuthorizationRights(count: 1, items: &authItem)
        let authFlags = AuthorizationFlags(rawValue: 1 | 2 | 16)
        let rightsStatus = AuthorizationCopyRights(authRef, &authRights, nil, authFlags, nil)
        guard rightsStatus == errAuthorizationSuccess else {
            throw PrivilegedHelperClientError.installationFailed(message(for: rightsStatus))
        }

        var unmanagedError: Unmanaged<CFError>?
        let blessSucceeded = SMJobBless(
            kSMDomainSystemLaunchd,
            ShecanHelperConstants.machServiceName as CFString,
            authRef,
            &unmanagedError
        )

        if !blessSucceeded {
            let message = unmanagedError?.takeRetainedValue().localizedDescription ?? "The privileged helper could not be installed."
            throw PrivilegedHelperClientError.installationFailed(message)
        }

        connection?.invalidate()
        connection = nil
    }

    private func helperProxy(errorHandler: @escaping (Error) -> Void) throws -> ShecanPrivilegedHelperProtocol {
        if connection == nil {
            let connection = NSXPCConnection(machServiceName: ShecanHelperConstants.machServiceName, options: .privileged)
            connection.remoteObjectInterface = NSXPCInterface(with: ShecanPrivilegedHelperProtocol.self)
            connection.invalidationHandler = { [weak self] in
                self?.connection = nil
            }
            connection.interruptionHandler = { [weak self] in
                self?.connection = nil
            }
            connection.resume()
            self.connection = connection
        }

        guard let connection else {
            throw PrivilegedHelperClientError.connectionFailed("The helper connection could not be created.")
        }

        let errorProxy = connection.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.connection?.invalidate()
            self?.connection = nil
            errorHandler(error)
        }

        guard let proxy = errorProxy as? ShecanPrivilegedHelperProtocol else {
            throw PrivilegedHelperClientError.connectionFailed("The helper connection is invalid.")
        }

        return proxy
    }

    private func message(for status: OSStatus) -> String {
        if let cfMessage = SecCopyErrorMessageString(status, nil) {
            return cfMessage as String
        }

        switch status {
        case errAuthorizationCanceled:
            return "Administrator authorization was cancelled."
        case errAuthorizationDenied:
            return "Administrator authorization was denied."
        default:
            return "The privileged helper could not be authorized."
        }
    }
}
