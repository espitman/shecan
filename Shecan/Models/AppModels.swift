import Foundation

enum DNSMode: String {
    case automatic
    case shecan
    case custom
    case unknown

    var title: String {
        switch self {
        case .automatic:
            return "Automatic"
        case .shecan:
            return "Shecan DNS Active"
        case .custom:
            return "Custom DNS Detected"
        case .unknown:
            return "Unknown"
        }
    }
}

struct NetworkServiceStatus: Equatable {
    let serviceName: String
    let device: String
    let mode: DNSMode
    let dnsServers: [String]
}

enum UpdateState: Equatable {
    case idle
    case updating
    case succeeded(Date)
    case failed(String)

    var title: String {
        switch self {
        case .idle:
            return "Idle"
        case .updating:
            return "Updating"
        case .succeeded:
            return "Last update succeeded"
        case .failed:
            return "Last update failed"
        }
    }
}
