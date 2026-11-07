import SwiftUI

/// Privacy summary, honest limits, reset. All texts are plain Turkish and kept short.
struct SettingsView: View {
    @ObservedObject var store: RuleStore
    @State private var confirmingReset = false

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if AdsConfig.isEnabled {
                        Text("Numaralarınız, kurallarınız ve mesajlarınız cihazınızdan çıkmaz.")
                            .font(.headline)
                        Text("Hesap yok, Sessiz'in kendi sunucusu yok, istatistik toplamıyoruz. Sadece Numaralar ve Mesajlar sekmelerinin altındaki reklamlar Google AdMob tarafından gösterilir; reklam hizmeti cihaz bilgisi (IP adresi gibi) kullanabilir. Reklamlar kişiselleştirilmez.")
                            .foregroundStyle(Theme.secondaryText)
                    } else {
                        Text("Hiçbir veri cihazından çıkmaz.")
                            .font(.headline)
                        Text("Hesap yok, sunucu yok, istatistik toplama yok. Numaralarınız ve kurallarınız sadece bu iPhone'da durur.")
                            .foregroundStyle(Theme.secondaryText)
                    }
                } header: {
                    Text("Gizlilik").foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.surface)

                Section {
                    LimitRow(text: "iMessage mesajları filtrelenemez. Sadece SMS ve MMS filtrelenir.")
                    LimitRow(text: "Rehberinizdeki kişilerin mesajları filtrelenmez.")
                    LimitRow(text: "Kaç mesaj ya da arama engellendiğini iPhone uygulamaya bildirmez, bu yüzden sayaç yok.")
                    LimitRow(text: "Arama engelleme sadece listedeki numaralarla çalışır. Numara değiştiren aramalar geçebilir.")
                } header: {
                    Text("Sınırlar").foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.surface)

                Section {
                    NavigationLink("Koruma rehberi") { ProtectionGuideView() }
                } footer: {
                    Text("Numara listesiyle çözülemeyen tehditler için kısa öneriler.")
                        .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.surface)

                Section {
                    Button("Kuralları sıfırla", role: .destructive) { confirmingReset = true }
                } footer: {
                    Text("Hazır kurallar geri gelir, eklediğiniz kurallar silinir. Engellenen numaralar etkilenmez.")
                        .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.surface)

                Section {
                    LabeledContent("Sürüm", value: versionText)
                }
                .listRowBackground(Theme.surface)
            }
            .foregroundStyle(Theme.text)
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Ayarlar")
            .confirmationDialog("Kurallar sıfırlansın mı?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Sıfırla", role: .destructive) { store.resetToDefaults() }
                Button("Vazgeç", role: .cancel) {}
            }
        }
    }
}

private struct LimitRow: View {
    let text: String

    var body: some View {
        Text(text).fixedSize(horizontal: false, vertical: true)
    }
}
