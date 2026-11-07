import SwiftUI

struct RootView: View {
    /// One store shared by the Messages and Settings tabs, so a reset shows up immediately.
    @StateObject private var ruleStore = RuleStore()

    var body: some View {
        TabView {
            StatusView()
                .tabItem { Label("Durum", systemImage: "checklist") }
            NumbersView()
                .tabItem { Label("Numaralar", systemImage: "phone") }
            MessagesView(store: ruleStore)
                .tabItem { Label("Mesajlar", systemImage: "message") }
            SettingsView(store: ruleStore)
                .tabItem { Label("Ayarlar", systemImage: "gearshape") }
        }
        .tint(Theme.selection)
    }
}
