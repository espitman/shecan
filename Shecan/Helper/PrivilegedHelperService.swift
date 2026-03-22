import Foundation

final class PrivilegedHelperService: NSObject, NSXPCListenerDelegate, ShecanPrivilegedHelperProtocol {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: ShecanPrivilegedHelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }

    func setDNSServers(
        forService service: String,
        servers: [String],
        withReply reply: @escaping (Bool, String?) -> Void
    ) {
        guard isValidServiceName(service), !servers.isEmpty, servers.allSatisfy(isValidIPv4Address) else {
            reply(false, "The DNS request is invalid.")
            return
        }

        runNetworkSetup(arguments: ["-setdnsservers", service] + servers, reply: reply)
    }

    func restoreAutomaticDNS(
        forService service: String,
        withReply reply: @escaping (Bool, String?) -> Void
    ) {
        guard isValidServiceName(service) else {
            reply(false, "The network service is invalid.")
            return
        }

        runNetworkSetup(arguments: ["-setdnsservers", service, "empty"], reply: reply)
    }

    private func runNetworkSetup(arguments: [String], reply: @escaping (Bool, String?) -> Void) {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process.arguments = arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            reply(false, error.localizedDescription)
            return
        }

        let stdout = String(decoding: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let stderr = String(decoding: stderrPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let message = (stderr.isEmpty ? stdout : stderr).trimmingCharacters(in: .whitespacesAndNewlines)

        if process.terminationStatus == 0 {
            reply(true, nil)
        } else {
            reply(false, message.isEmpty ? "networksetup failed." : message)
        }
    }

    private func isValidServiceName(_ service: String) -> Bool {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_/")
        return !service.isEmpty && service.rangeOfCharacter(from: allowed.inverted) == nil
    }

    private func isValidIPv4Address(_ value: String) -> Bool {
        let components = value.split(separator: ".")
        guard components.count == 4 else { return false }

        return components.allSatisfy { component in
            guard let octet = Int(component), component == String(octet) else {
                return false
            }
            return (0...255).contains(octet)
        }
    }
}
