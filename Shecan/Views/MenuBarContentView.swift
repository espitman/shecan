import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.openWindow) private var openWindow

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Shecan")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(viewModel.connectionHeadline)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Circle()
                    .fill(viewModel.isShecanDNSActive ? .green : .secondary.opacity(0.45))
                    .frame(width: 10, height: 10)
                Text(viewModel.connectionSubtitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Last update")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(viewModel.lastUpdateText(formatter: dateFormatter))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }

            Divider()

            Button(viewModel.isShecanDNSActive ? "Disable Shecan DNS" : "Enable Shecan DNS") {
                viewModel.toggleDNS()
            }

            Button("Open Main Window") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }

            Button("Settings") {
                viewModel.openSettings()
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }

            Button("Refresh Status") {
                viewModel.refreshDNSStatus()
            }

            Button("Update Now") {
                viewModel.updateNow()
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 300)
    }
}
