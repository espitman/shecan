import Combine
import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    private enum DefaultsKey {
        static let lastUpdate = "last-update-at"
        static let dnsPrimary = "dns-primary"
        static let dnsSecondary = "dns-secondary"
    }

    @Published var dnsStatus: NetworkServiceStatus?
    @Published var updaterURL: String = ""
    @Published var dnsPrimary: String = DNSManager.defaultShecanDNS[0]
    @Published var dnsSecondary: String = DNSManager.defaultShecanDNS[1]
    @Published var updateState: UpdateState = .idle
    @Published var bannerMessage: String?
    @Published var isBusy = false
    @Published var isShowingSettings = false

    private let linkUpdater = LinkUpdaterService()
    private var timerCancellable: AnyCancellable?

    init() {
        updaterURL = KeychainHelper.loadURL() ?? ""
        dnsPrimary = UserDefaults.standard.string(forKey: DefaultsKey.dnsPrimary) ?? DNSManager.defaultShecanDNS[0]
        dnsSecondary = UserDefaults.standard.string(forKey: DefaultsKey.dnsSecondary) ?? DNSManager.defaultShecanDNS[1]
        if let lastUpdate = UserDefaults.standard.object(forKey: DefaultsKey.lastUpdate) as? Date {
            updateState = .succeeded(lastUpdate)
        }
        refreshDNSStatus()
        startTimer()
    }

    var isShecanDNSActive: Bool {
        dnsStatus?.mode == .shecan
    }

    var configuredDNSServers: [String] {
        [dnsPrimary, dnsSecondary]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var serviceLabel: String {
        dnsStatus?.serviceName ?? "Unavailable"
    }

    var connectionHeadline: String {
        isShecanDNSActive ? "Shecan DNS" : "Ready to Protect"
    }

    var connectionSubtitle: String {
        if let dnsStatus {
            return isShecanDNSActive ? "Active on \(dnsStatus.serviceName)" : "Available on \(dnsStatus.serviceName)"
        }

        return "No active interface"
    }

    var dnsStatusHeadline: String {
        dnsStatus?.mode.title ?? "Unavailable"
    }

    var updaterStatusTitle: String {
        switch updateState {
        case .idle:
            return "Waiting for first refresh"
        case .updating:
            return "Refreshing whitelist..."
        case .succeeded:
            return "Whitelist is current"
        case .failed:
            return "Needs attention"
        }
    }

    var dnsServersLabel: String {
        guard let dnsStatus else {
            return "No active interface detected"
        }

        if dnsStatus.dnsServers.isEmpty {
            return "Automatic DNS"
        }

        return dnsStatus.dnsServers.joined(separator: " , ")
    }

    func refreshDNSStatus() {
        do {
            dnsStatus = try dnsManager.activeServiceStatus()
        } catch {
            dnsStatus = nil
            bannerMessage = error.localizedDescription
        }
    }

    func toggleDNS() {
        Task {
            if isShecanDNSActive {
                await restoreAutomatic()
            } else {
                await enableShecan()
            }
        }
    }

    func enableShecan() async {
        await runBusyTask {
            try dnsManager.enableShecanDNS()
            refreshDNSStatus()
            bannerMessage = "Shecan DNS applied to \(serviceLabel)."
        }
    }

    func restoreAutomatic() async {
        await runBusyTask {
            try dnsManager.restoreAutomaticDNS()
            refreshDNSStatus()
            bannerMessage = "DNS restored to automatic for \(serviceLabel)."
        }
    }

    func saveSettings() {
        do {
            try KeychainHelper.save(url: updaterURL.trimmingCharacters(in: .whitespacesAndNewlines))
            UserDefaults.standard.set(dnsPrimary.trimmingCharacters(in: .whitespacesAndNewlines), forKey: DefaultsKey.dnsPrimary)
            UserDefaults.standard.set(dnsSecondary.trimmingCharacters(in: .whitespacesAndNewlines), forKey: DefaultsKey.dnsSecondary)
            refreshDNSStatus()
            bannerMessage = "Settings saved."
            closeSettings()
        } catch {
            bannerMessage = error.localizedDescription
        }
    }

    func updateNow() {
        Task {
            await performUpdate(silent: false)
        }
    }

    func openSettings() {
        isShowingSettings = true
    }

    func closeSettings() {
        isShowingSettings = false
    }

    func lastUpdateText(formatter: DateFormatter) -> String {
        switch updateState {
        case .idle:
            return "No update yet"
        case .updating:
            return "Updating now..."
        case .succeeded(let date):
            return formatter.string(from: date)
        case .failed(let message):
            return message
        }
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.performUpdate(silent: true)
                }
            }
    }

    private func performUpdate(silent: Bool) async {
        let trimmedURL = updaterURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            if !silent {
                updateState = .failed(LinkUpdaterError.missingURL.localizedDescription)
            }
            return
        }

        updateState = .updating

        do {
            let updatedAt = try await linkUpdater.performUpdate(with: trimmedURL)
            updateState = .succeeded(updatedAt)
            UserDefaults.standard.set(updatedAt, forKey: DefaultsKey.lastUpdate)
            if !silent {
                bannerMessage = "IP whitelist updated successfully."
            }
        } catch {
            updateState = .failed(error.localizedDescription)
            if !silent {
                bannerMessage = error.localizedDescription
            }
        }
    }

    private func runBusyTask(_ task: () throws -> Void) async {
        isBusy = true
        defer { isBusy = false }

        do {
            try task()
        } catch {
            bannerMessage = error.localizedDescription
        }
    }

    private var dnsManager: DNSManager {
        DNSManager(shecanDNS: configuredDNSServers.count == 2 ? configuredDNSServers : DNSManager.defaultShecanDNS)
    }
}
