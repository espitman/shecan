import Foundation

enum DNSManagerError: LocalizedError {
    case noSupportedActiveService
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .noSupportedActiveService:
            return "No active Wi-Fi or Ethernet service was found."
        case .commandFailed(let message):
            return message
        }
    }
}

struct DNSManager {
    static let defaultShecanDNS = ["178.22.122.101", "185.51.200.1"]
    private let supportedPorts = ["Wi-Fi", "Ethernet", "USB 10/100/1000 LAN", "Thunderbolt Ethernet"]
    let shecanDNS: [String]

    init(shecanDNS: [String] = DNSManager.defaultShecanDNS) {
        self.shecanDNS = shecanDNS
    }

    func activeServiceStatus() throws -> NetworkServiceStatus {
        let service = try activeService()
        let dnsServers = try currentDNSServers(serviceName: service.serviceName)
        let mode: DNSMode

        if dnsServers.isEmpty {
            mode = .automatic
        } else if dnsServers == shecanDNS {
            mode = .shecan
        } else {
            mode = .custom
        }

        return NetworkServiceStatus(
            serviceName: service.serviceName,
            device: service.device,
            mode: mode,
            dnsServers: dnsServers
        )
    }

    func enableShecanDNS() throws {
        let service = try activeService()
        try PrivilegedHelperClient.shared.setDNSServers(serviceName: service.serviceName, servers: shecanDNS)
    }

    func restoreAutomaticDNS() throws {
        let service = try activeService()
        try PrivilegedHelperClient.shared.restoreAutomaticDNS(serviceName: service.serviceName)
    }

    private func activeService() throws -> (serviceName: String, device: String) {
        let mapping = try hardwarePortMapping()

        for port in supportedPorts {
            guard let device = mapping[port], interfaceIsActive(device: device) else {
                continue
            }

            return (port, device)
        }

        if let primaryDevice = try primaryInterface(),
           let serviceName = try networkServiceName(for: primaryDevice),
           interfaceIsActive(device: primaryDevice) {
            return (serviceName, primaryDevice)
        }

        throw DNSManagerError.noSupportedActiveService
    }

    private func hardwarePortMapping() throws -> [String: String] {
        let output = try runCommand("/usr/sbin/networksetup", arguments: ["-listallhardwareports"])
        let lines = output.split(separator: "\n").map(String.init)
        var mapping: [String: String] = [:]
        var currentPort: String?

        for line in lines {
            if line.hasPrefix("Hardware Port: ") {
                currentPort = String(line.dropFirst("Hardware Port: ".count))
            } else if line.hasPrefix("Device: "), let currentPort {
                mapping[currentPort] = String(line.dropFirst("Device: ".count))
            }
        }

        return mapping
    }

    private func primaryInterface() throws -> String? {
        let output = try runCommand("/sbin/route", arguments: ["-n", "get", "default"])
        for line in output.split(separator: "\n").map(String.init) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("interface:") {
                return trimmed
                    .replacingOccurrences(of: "interface:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    private func networkServiceName(for device: String) throws -> String? {
        let output = try runCommand("/usr/sbin/networksetup", arguments: ["-listnetworkserviceorder"])
        let lines = output.split(separator: "\n").map(String.init)
        var currentService: String?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.hasPrefix("("), let range = trimmed.range(of: ") ") {
                currentService = String(trimmed[range.upperBound...])
            } else if trimmed.contains("Device: \(device)"), let currentService {
                return currentService
            }
        }

        return nil
    }

    private func interfaceIsActive(device: String) -> Bool {
        guard let output = try? runCommand("/sbin/ifconfig", arguments: [device]) else {
            return false
        }

        return output.contains("status: active")
    }

    private func currentDNSServers(serviceName: String) throws -> [String] {
        let output = try runCommand("/usr/sbin/networksetup", arguments: ["-getdnsservers", serviceName])
        if output.contains("There aren't any DNS Servers set") {
            return []
        }

        return output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func runCommand(_ launchPath: String, arguments: [String]) throws -> String {
        let process = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(decoding: outPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let stderr = String(decoding: errPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)

        guard process.terminationStatus == 0 else {
            let message = stderr.isEmpty ? stdout : stderr
            throw DNSManagerError.commandFailed(message.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
