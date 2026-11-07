import SwiftUI
import UIKit

/// Setup / status screen. When both items are done it shows only two quiet status lines.
struct StatusView: View {
    @StateObject private var status = SetupStatus()
    @AppStorage("messagesSetupConfirmed") private var messagesConfirmed = false
    @Environment(\.scenePhase) private var scenePhase

    // Menu names can change between iOS versions; keep every setup text in one place.
    private let callSteps = [
        "Ayarlar > Uygulamalar > Telefon > Arama Engelleme ve Kimlik'i açın.",
        "\"Sessiz Arama Engelleme\"yi açın."
    ]
    private let messageSteps = [
        "Ayarlar > Mesajlar > Bilinmeyen ve Spam'i açın.",
        "SMS Filtreleme'de \"Sessiz Mesaj Filtresi\"ni seçin.",
        "Buraya dönüp \"Kurulumu tamamladım\"ı açın."
    ]

    private var callsDone: Bool { status.calls == .enabled }

    var body: some View {
        NavigationStack {
            List {
                callsSection
                messagesSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Durum")
        }
        .onAppear { status.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { status.refresh() }
        }
    }

    // MARK: Calls

    private var callsSection: some View {
        Section("Aramalar") {
            LabeledContent("Durum", value: callsStatusText)
            if !callsDone && status.calls != .checking {
                StepList(steps: callSteps)
                Button("Ayarlar'ı aç") { status.openCallSettings() }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityHint("Telefon ayarlarındaki arama engelleme sayfasını açar.")
            }
        }
        .listRowBackground(Theme.surface)
        .foregroundStyle(Theme.text)
    }

    private var callsStatusText: String {
        switch status.calls {
        case .checking: return "Kontrol ediliyor"
        case .enabled: return "Açık"
        case .disabled: return "Kapalı"
        case .unreadable: return "Okunamadı"
        }
    }

    // MARK: Messages

    private var messagesSection: some View {
        Section {
            LabeledContent("Durum", value: messagesConfirmed ? "Açık (senin onayınla)" : "Kapalı")
            Toggle("Kurulumu tamamladım", isOn: $messagesConfirmed)
                .tint(Theme.accent)
            if !messagesConfirmed {
                StepList(steps: messageSteps)
                messagesButton
            }
        } header: {
            Text("Mesajlar")
        } footer: {
            if !messagesConfirmed {
                Text("iPhone, mesaj filtresinin açık olup olmadığını uygulamalara söylemez. Kurulumu bitirince yukarıdan kendiniz işaretleyin.")
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .listRowBackground(Theme.surface)
        .foregroundStyle(Theme.text)
    }

    /// Only one primary button on screen: the Messages button is primary once Calls are done.
    @ViewBuilder private var messagesButton: some View {
        if callsDone {
            Button("Ayarlar'ı aç") { openAppSettings() }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityHint("iPhone Ayarları'nı açar.")
        } else {
            Button("Ayarlar'ı aç") { openAppSettings() }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint("iPhone Ayarları'nı açar.")
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct StepList: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                Text("\(index + 1). \(step)")
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
