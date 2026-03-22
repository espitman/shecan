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

        runNetworkSetup(arguments: ["-setdnsservers", service, "empty"]) { [self] success, message in
            guard success else {
                reply(false, message)
                return
            }

            do {
                try disconnectConnectedVPNs()
                reply(true, nil)
            } catch {
                reply(false, error.localizedDescription)
            }
        }
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

    private func disconnectConnectedVPNs() throws {
        let output = try runCommand("/usr/sbin/scutil", arguments: ["--nc", "list"])
        let connectedIdentifiers = output
            .split(separator: "\n")
            .map(String.init)
            .compactMap(connectedVPNIdentifier(from:))

        for identifier in connectedIdentifiers {
            _ = try runCommand("/usr/sbin/scutil", arguments: ["--nc", "stop", identifier])
        }
    }

    private func connectedVPNIdentifier(from line: String) -> String? {
        guard line.contains("(Connected)") else {
            return nil
        }

        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count >= 3 else {
            return nil
        }

        let candidate = String(parts[2])
        let allowed = CharacterSet(charactersIn: "0123456789ABCDEF-")
        guard candidate.count == 36, candidate.rangeOfCharacter(from: allowed.inverted) == nil else {
            return nil
        }

        return candidate
    }

    @discardableResult
    private func runCommand(_ launchPath: String, arguments: [String]) throws -> String {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(decoding: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let stderr = String(decoding: stderrPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let message = (stderr.isEmpty ? stdout : stderr).trimmingCharacters(in: .whitespacesAndNewlines)

        guard process.terminationStatus == 0 else {
            throw NSError(domain: "PrivilegedHelperService", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message.isEmpty ? "\(launchPath) failed." : message
            ])
        }

        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
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
