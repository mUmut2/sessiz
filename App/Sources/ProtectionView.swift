import SpamCore
import SwiftUI

/// Built-in spam number list: three levels the user can switch on or off.
struct ProtectionView: View {
    @ObservedObject var store: BlocklistStore

    private struct Level {
        let level: ProtectionLevel
        let title: String
        let detail: String
    }

    private let levels: [Level] = [
        Level(level: .basic, title: "Temel",
              detail: "Birden fazla kişinin şikayet ettiği numaralar."),
        Level(level: .strict, title: "Sıkı",
              detail: "Şikayetlerin yoğunlaştığı dar bloklar: 0850 484, 0850 430, 0850 901 0 ve 0212 922. Bu bloklardaki meşru bir arama da engellenebilir."),
        Level(level: .suspicious, title: "Şüpheli",
              detail: "Tek şikayeti olan numaralar. Yanlış engelleme ihtimali daha yüksek.")
    ]

    var body: some View {
        List {
            Section {
                Text("Liste uygulamanın içindedir, internetten indirilmez. Numaralar herkese açık şikayet kayıtlarından elle seçildi, kişilere ait cep numarası içermez.")
                    .foregroundStyle(Theme.secondaryText)
            } footer: {
                Text("Son kontrol: \(BuiltInSpamList.reviewedOn)").foregroundStyle(Theme.secondaryText)
            }
            .listRowBackground(Theme.surface)

            ForEach(levels, id: \.level) { item in
                Section {
                    Toggle(isOn: Binding(
                        get: { store.protection.isOn(item.level) },
                        set: { store.setProtection(item.level, on: $0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).foregroundStyle(Theme.text)
                            Text("\(BuiltInSpamList.count(for: item.level).formatted()) numara")
                                .font(.subheadline)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .tint(Theme.accent)
                    .accessibilityElement(children: .combine)
                } footer: {
                    Text(item.detail).foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.surface)
            }

            Section {
                Text("Bankaların, kargo firmalarının ve operatörlerin resmî numaraları hazır listeden her zaman çıkarılır. Yine de sahte aramalar bu numaraları taklit edebilir: bir bankadan arandığınızı düşünüyorsanız kapatın ve bankanın kendi numarasını siz arayın.")
                    .foregroundStyle(Theme.secondaryText)
                Text("Bir numara yanlışlıkla engellendiyse ilgili seviyeyi kapatın.")
                    .foregroundStyle(Theme.secondaryText)
            }
            .listRowBackground(Theme.surface)
        }
        .foregroundStyle(Theme.text)
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Hazır liste")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Threats a number list cannot solve. Plain advice, no promises.
struct ProtectionGuideView: View {
    private let items: [(title: String, text: String)] = [
        ("Bilinmeyen aramaları sustur",
         "Ayarlar'da Telefon bölümünden \"Bilinmeyen Aramaları Sustur\"u açabilirsiniz. Rehberinizde olmayan numaralar sessize alınır. Kargo ya da doktor gibi beklediğiniz aramalar da sessize düşer, Son Aramalar'a bakmayı unutmayın."),
        ("Yurt dışından çal-kapat aramaları",
         "Bir kez çalıp kapanan yurt dışı numaralarını (+225, +233, +234, +252 gibi) geri aramayın, geri arama ücretli olabilir. İsterseniz operatörünüzden yurt dışı aramalara kapatmasını isteyin."),
        ("Ticari arama ve mesajları reddet",
         "e-Devlet üzerinden İleti Yönetim Sistemi'ne girip ticari arama ve mesaj iznini reddedebilirsiniz."),
        ("Banka, polis ya da savcı arıyorsa",
         "Hiçbir kurum telefonda şifre, kart bilgisi ya da para transferi istemez. Ekranda görünen numara taklit edilebilir, tek başına güvenilir değildir. Kapatın ve kurumun kendi resmî numarasını siz arayın.")
    ]

    var body: some View {
        List {
            ForEach(items, id: \.title) { item in
                Section {
                    Text(item.text)
                        .fixedSize(horizontal: false, vertical: true)
                } header: {
                    Text(item.title).foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.surface)
            }
        }
        .foregroundStyle(Theme.text)
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Koruma rehberi")
        .navigationBarTitleDisplayMode(.inline)
    }
}
