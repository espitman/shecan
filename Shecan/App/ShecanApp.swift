import SwiftUI

@main
struct ShecanApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup("Shecan", id: "main") {
            DashboardView(viewModel: viewModel)
                .frame(minWidth: 414, idealWidth: 414, maxWidth: 414, minHeight: 458, idealHeight: 458, maxHeight: 458)
        }
        .defaultSize(width: 414, height: 458)
        .windowResizability(.contentSize)

        MenuBarExtra("Shecan", systemImage: viewModel.isShecanDNSActive ? "bolt.horizontal.circle.fill" : "bolt.horizontal.circle") {
            MenuBarContentView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
