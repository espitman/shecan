import SwiftUI
import AppKit

struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        GeometryReader { proxy in
            let metrics = DashboardMetrics(size: proxy.size)

            ZStack {
                ShecanPalette.background
                    .ignoresSafeArea()

                decorativeBackground(metrics: metrics)

                VStack(spacing: metrics.sectionSpacing) {
                    header
                    heroCard(metrics: metrics)
                    infoCard(
                        title: "LINK UPDATER",
                        primary: "",
                        secondary: "Last update: \(viewModel.lastUpdateText(formatter: dateFormatter))",
                        showsStatusDot: true,
                        actionTitle: "Update Now",
                        action: viewModel.updateNow,
                        metrics: metrics
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.top, metrics.topPadding)
                .padding(.bottom, metrics.bottomPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if viewModel.isShowingSettings {
                    settingsOverlay
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.9), value: viewModel.isShowingSettings)
        }
    }

    private func decorativeBackground(metrics: DashboardMetrics) -> some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(ShecanPalette.blobPrimary)
                    .frame(width: metrics.blobPrimarySize, height: metrics.blobPrimarySize)
                    .offset(x: proxy.size.width * 0.34, y: -proxy.size.height * 0.37)

                Circle()
                    .fill(ShecanPalette.blobSecondary)
                    .frame(width: metrics.blobSecondarySize, height: metrics.blobSecondarySize)
                    .offset(x: -proxy.size.width * 0.37, y: proxy.size.height * 0.38)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shecan")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(ShecanPalette.textPrimary)

                    Text("Secure DNS control for macOS")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(ShecanPalette.textSecondary)
                }

                statusPill
            }

            Spacer(minLength: 12)

            Button {
                viewModel.openSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ShecanPalette.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusPill: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(viewModel.isShecanDNSActive ? ShecanPalette.accent : ShecanPalette.textSecondary.opacity(0.4))
                .frame(width: 10, height: 10)

            Text(viewModel.serviceLabel)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(ShecanPalette.accentText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(ShecanPalette.pill, in: Capsule())
    }

    private func heroCard(metrics: DashboardMetrics) -> some View {
        VStack(spacing: metrics.heroSpacing) {
            VStack(spacing: metrics.heroInnerSpacing) {
                Button(action: viewModel.toggleDNS) {
                    ZStack {
                        Circle()
                            .fill(viewModel.isShecanDNSActive ? ShecanPalette.orbHalo : ShecanPalette.orbHaloOff)
                            .frame(width: metrics.orbHaloSize, height: metrics.orbHaloSize)

                        Circle()
                            .fill(viewModel.isShecanDNSActive ? AnyShapeStyle(ShecanPalette.orb) : AnyShapeStyle(ShecanPalette.orbOff))
                            .frame(width: metrics.orbSize, height: metrics.orbSize)
                            .shadow(color: ShecanPalette.shadow, radius: 24, y: 12)

                        Image(systemName: "power")
                            .font(.system(size: metrics.powerIconSize, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 4)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isBusy)

                VStack(spacing: 8) {
                    Text(viewModel.isShecanDNSActive ? "CONNECTED" : "STANDBY")
                        .font(.system(size: metrics.badgeFontSize, weight: .bold, design: .rounded))
                        .tracking(2.2)
                        .foregroundStyle(viewModel.isShecanDNSActive ? ShecanPalette.accent : ShecanPalette.textSecondary)

                    Text(viewModel.connectionHeadline)
                        .font(.system(size: metrics.connectionTitleFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(ShecanPalette.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(viewModel.connectionSubtitle)
                        .font(.system(size: metrics.connectionSubtitleFontSize, weight: .medium, design: .rounded))
                        .foregroundStyle(ShecanPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(height: metrics.heroTextBlockHeight)

                Group {
                    if let bannerMessage = viewModel.bannerMessage {
                        Text(bannerMessage)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(ShecanPalette.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(ShecanPalette.cardSubtle, in: Capsule())
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    } else {
                        Color.clear
                    }
                }
                .frame(height: metrics.bannerHeight)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, metrics.heroVerticalPadding)
        }
        .padding(.horizontal, metrics.heroHorizontalPadding)
        .padding(.vertical, metrics.heroOuterVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: metrics.heroCornerRadius, style: .continuous)
                .fill(ShecanPalette.card)
                .shadow(color: ShecanPalette.shadow, radius: 34, y: 18)
        )
    }

    private func infoCard(
        title: String,
        primary: String,
        secondary: String,
        primaryFont: Font = .system(size: 28, weight: .bold, design: .rounded),
        showsStatusDot: Bool = false,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        metrics: DashboardMetrics
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                if showsStatusDot {
                    Circle()
                        .fill(viewModel.updaterURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.red.opacity(0.9) : ShecanPalette.accent)
                        .frame(width: 10, height: 10)
                }

                Text(title)
                    .font(.system(size: metrics.cardLabelFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(ShecanPalette.textTertiary)

                Spacer()

                if let actionTitle, let action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .frame(minWidth: 72)
                    }
                    .buttonStyle(ShecanSecondaryButtonStyle())
                }
            }
            .padding(.bottom, metrics.cardTitleBottomPadding)

            if !showsStatusDot {
                Text(primary)
                    .font(primaryFont)
                    .foregroundStyle(ShecanPalette.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .padding(.bottom, metrics.cardPrimaryBottomPadding)
            }

            Text(secondary)
                .font(.system(size: metrics.cardSecondaryFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(ShecanPalette.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: metrics.cardMinHeight, alignment: .leading)
        .padding(.horizontal, metrics.cardHorizontalPadding)
        .padding(.vertical, metrics.cardVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: metrics.cardCornerRadius, style: .continuous)
                .fill(ShecanPalette.card)
                .shadow(color: ShecanPalette.softShadow, radius: 18, y: 10)
        )
    }

    private var settingsOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.16)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.closeSettings()
                }

            SettingsSheetView(viewModel: viewModel)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
        }
    }
}

struct SettingsSheetView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showSandboxAlert = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Settings")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(ShecanPalette.textPrimary)

                    Text("Manage your LinkUpdater URL here.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(ShecanPalette.textSecondary)
                }

                Spacer(minLength: 12)

                Button {
                    viewModel.closeSettings()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ShecanPalette.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.8), in: Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("DNS SERVERS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(ShecanPalette.textTertiary)

                HStack(spacing: 10) {
                    settingsTextField(text: $viewModel.dnsPrimary, placeholder: "178.22.122.101")
                    settingsTextField(text: $viewModel.dnsSecondary, placeholder: "185.51.200.1")
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("LINK UPDATER")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(ShecanPalette.textTertiary)

                settingsTextField(text: $viewModel.updaterURL, placeholder: "https://ddns.shecan.ir/update?password=xxx")

                Button {
                    if let pasted = NSPasteboard.general.string(forType: .string) {
                        viewModel.updaterURL = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                } label: {
                    Text("Paste")
                        .frame(width: 72)
                }
                .buttonStyle(ShecanSecondaryButtonStyle())

                Text("Last update: \(viewModel.lastUpdateText(formatter: dateFormatter))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(ShecanPalette.textSecondary)
            }

            HStack(spacing: 10) {
                Button(action: viewModel.saveSettings) {
                    Text("Save Settings")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ShecanPrimaryButtonStyle())

                Button(action: viewModel.updateNow) {
                    Text("Update Now")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ShecanSecondaryButtonStyle())
            }

            HStack {
                Text(viewModel.updaterStatusTitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(ShecanPalette.textSecondary)

                Spacer()

                Button("Sandbox notes") {
                    showSandboxAlert = true
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(ShecanPalette.accent)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(ShecanPalette.card)
                .shadow(color: ShecanPalette.shadow, radius: 24, y: 12)
        )
        .alert("Sandbox Requirement", isPresented: $showSandboxAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The app must run without App Sandbox to control DNS via networksetup and administrator authorization.")
        }
    }

    private func settingsTextField(text: Binding<String>, placeholder: String) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(verbatim: placeholder)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
            }

            TextField("", text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(ShecanPalette.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(height: 22)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 0.73, green: 0.77, blue: 0.75), lineWidth: 1.2)
        )
    }
}

private struct DashboardMetrics {
    let size: CGSize

    var compactHeight: Bool { size.height < 700 }
    var compactWidth: Bool { size.width < 360 }

    var horizontalPadding: CGFloat { compactWidth ? 8 : 10 }
    var topPadding: CGFloat { compactHeight ? 10 : 12 }
    var bottomPadding: CGFloat { compactHeight ? 10 : 12 }
    var sectionSpacing: CGFloat { compactHeight ? 8 : 10 }

    var blobPrimarySize: CGFloat { compactHeight ? 90 : 110 }
    var blobSecondarySize: CGFloat { compactHeight ? 130 : 150 }

    var heroSpacing: CGFloat { compactHeight ? 6 : 8 }
    var heroInnerSpacing: CGFloat { compactHeight ? 8 : 10 }
    var heroVerticalPadding: CGFloat { compactHeight ? 6 : 8 }
    var heroOuterVerticalPadding: CGFloat { compactHeight ? 10 : 12 }
    var heroHorizontalPadding: CGFloat { compactWidth ? 12 : 14 }
    var heroCornerRadius: CGFloat { compactHeight ? 20 : 22 }

    var titleFontSize: CGFloat { compactHeight ? 12 : 13 }
    var subtitleFontSize: CGFloat { compactHeight ? 10 : 11 }
    var badgeFontSize: CGFloat { compactHeight ? 11 : 12 }
    var connectionTitleFontSize: CGFloat { compactHeight ? 17 : 18 }
    var connectionSubtitleFontSize: CGFloat { compactHeight ? 11 : 12 }
    var heroTextBlockHeight: CGFloat { compactHeight ? 78 : 84 }
    var bannerHeight: CGFloat { compactHeight ? 28 : 32 }
    var orbHaloSize: CGFloat { compactHeight ? 92 : 102 }
    var orbSize: CGFloat { compactHeight ? 68 : 76 }
    var powerIconSize: CGFloat { compactHeight ? 24 : 28 }

    var cardLabelFontSize: CGFloat { compactHeight ? 10 : 11 }
    var cardTitleBottomPadding: CGFloat { compactHeight ? 6 : 8 }
    var cardPrimaryBottomPadding: CGFloat { compactHeight ? 4 : 5 }
    var cardSecondaryFontSize: CGFloat { compactHeight ? 10 : 11 }
    var cardMinHeight: CGFloat { compactHeight ? 62 : 68 }
    var cardHorizontalPadding: CGFloat { compactWidth ? 12 : 14 }
    var cardVerticalPadding: CGFloat { compactHeight ? 9 : 10 }
    var cardCornerRadius: CGFloat { compactHeight ? 16 : 18 }
    var linkPrimaryFontSize: CGFloat { compactHeight ? 11 : 12 }

    var buttonSpacing: CGFloat { compactWidth ? 6 : 7 }
}

enum ShecanPalette {
    static let background = LinearGradient(
        colors: [Color(red: 0.969, green: 0.976, blue: 0.961), Color(red: 0.929, green: 0.949, blue: 0.925)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let blobPrimary = Color(red: 0.894, green: 0.957, blue: 0.918)
    static let blobSecondary = Color(red: 0.941, green: 0.965, blue: 0.941)
    static let card = Color.white.opacity(0.96)
    static let cardSubtle = Color(red: 0.930, green: 0.960, blue: 0.943)
    static let pill = Color(red: 0.902, green: 0.961, blue: 0.925)
    static let orbHalo = Color(red: 0.915, green: 0.969, blue: 0.935)
    static let orbHaloOff = Color(red: 0.925, green: 0.929, blue: 0.941)
    static let orb = LinearGradient(
        colors: [Color(red: 0.098, green: 0.659, blue: 0.471), Color(red: 0.047, green: 0.471, blue: 0.345)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let orbOff = LinearGradient(
        colors: [Color(red: 0.667, green: 0.694, blue: 0.737), Color(red: 0.482, green: 0.510, blue: 0.561)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let accent = Color(red: 0.067, green: 0.639, blue: 0.435)
    static let accentText = Color(red: 0.086, green: 0.353, blue: 0.271)
    static let textPrimary = Color(red: 0.106, green: 0.165, blue: 0.137)
    static let textSecondary = Color(red: 0.447, green: 0.502, blue: 0.467)
    static let textTertiary = Color(red: 0.416, green: 0.467, blue: 0.439)
    static let shadow = Color(red: 0.09, green: 0.22, blue: 0.17).opacity(0.15)
    static let softShadow = Color(red: 0.09, green: 0.22, blue: 0.17).opacity(0.10)
}

struct ShecanPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(configuration.isPressed ? Color(red: 0.08, green: 0.54, blue: 0.39) : ShecanPalette.accent)
            )
    }
}

struct ShecanSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(ShecanPalette.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(configuration.isPressed ? Color(red: 0.89, green: 0.92, blue: 0.90) : Color(red: 0.925, green: 0.952, blue: 0.937))
            )
    }
}
