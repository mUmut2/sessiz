import SpamCore
import SwiftUI

/// Turkish labels for rule fields (all user-facing text lives in the app, not in SpamCore).
enum RuleText {
    static func action(_ action: RuleAction) -> String {
        action == .block ? "Engelle" : "İzin ver"
    }

    static func target(_ target: RuleTarget) -> String {
        target == .body ? "Mesaj metni" : "Gönderen adı"
    }

    static func mode(_ mode: MatchMode) -> String {
        switch mode {
        case .contains: return "İçerir"
        case .wholeWord: return "Tam kelime"
        case .prefix: return "Şununla başlar"
        case .exact: return "Aynısı"
        }
    }

    /// One line under a rule, e.g. "Engelle · Mesaj metni · İçerir".
    static func summary(_ rule: MessageRule) -> String {
        "\(action(rule.action)) · \(target(rule.target)) · \(mode(rule.mode))"
    }
}

struct MessagesView: View {
    @ObservedObject var store: RuleStore
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink("Test et") { TestMessageView(store: store) }
                        .foregroundStyle(Theme.text)
                } footer: {
                    Text("Bir mesaj yazın, Sessiz'in ne yapacağını görün.")
                        .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.surface)

                Section {
                    ForEach(store.ruleSet.userRules) { rule in
                        RuleToggleRow(rule: rule, title: rule.pattern, store: store)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.remove(rule)
                                } label: {
                                    Text("Sil")
                                }
                            }
                    }
                } header: {
                    Text("Kendi kurallarım").foregroundStyle(Theme.secondaryText)
                } footer: {
                    if store.ruleSet.userRules.isEmpty {
                        Text("Henüz kural eklemediniz. Sağ üstteki Ekle ile engellemek istediğiniz kelimeyi yazın.").foregroundStyle(Theme.secondaryText)
                    }
                }
                .listRowBackground(Theme.surface)

                Section {
                    NavigationLink("Hazır kurallar") { DefaultRulesView(store: store) }
                        .foregroundStyle(Theme.text)
                } footer: {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        if let problem = store.problem {
                            Text(problem).foregroundStyle(Theme.text)
                        }
                        Text("Doğrulama kodları ve banka ile e-Devlet mesajları her zaman geçer. Kuralla engellenemez.")
                        Text("Sadece rehberinizde olmayan kişilerden gelen SMS ve MMS filtrelenir. iMessage filtrelenemez.")
                    }
                    .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) { AdBannerSlot() }
            .navigationTitle("Mesajlar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Ekle") { showingAdd = true }
                        .foregroundStyle(Theme.text)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddRuleSheet(store: store)
        }
    }
}

/// A rule row with an on/off switch.
private struct RuleToggleRow: View {
    let rule: MessageRule
    let title: String
    @ObservedObject var store: RuleStore

    var body: some View {
        Toggle(isOn: Binding(
            get: { rule.isEnabled },
            set: { store.setEnabled($0, for: rule) }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(Theme.text)
                Text(RuleText.summary(rule))
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .tint(Theme.accent)
        .accessibilityElement(children: .combine)
    }
}

/// The shipped Turkish keyword pack. Rules can be switched off, not deleted.
struct DefaultRulesView: View {
    @ObservedObject var store: RuleStore

    /// Categories in the order they first appear in the pack.
    private var categories: [String] {
        var seen: [String] = []
        for rule in store.ruleSet.defaultRules where !seen.contains(rule.name) {
            seen.append(rule.name)
        }
        return seen
    }

    var body: some View {
        List {
            ForEach(categories, id: \.self) { category in
                Section {
                    ForEach(store.ruleSet.defaultRules.filter { $0.name == category }) { rule in
                        RuleToggleRow(rule: rule, title: rule.pattern, store: store)
                    }
                } header: {
                    Text(category).foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Hazır kurallar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddRuleSheet: View {
    @ObservedObject var store: RuleStore
    @Environment(\.dismiss) private var dismiss
    @State private var pattern = ""
    @State private var target: RuleTarget = .body
    @State private var mode: MatchMode = .contains
    @State private var action: RuleAction = .block
    @State private var errorText: String?
    @FocusState private var patternFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Kelime veya ifade", text: $pattern)
                        .focused($patternFocused)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Kuralın kelimesi veya ifadesi")
                } footer: {
                    if let errorText {
                        Text(errorText).foregroundStyle(Theme.text)
                    } else {
                        Text("Büyük küçük harf ve aksan fark etmez.").foregroundStyle(Theme.secondaryText)
                    }
                }
                .listRowBackground(Theme.surface)

                Section {
                    Picker("Ne yapılsın", selection: $action) {
                        Text(RuleText.action(.block)).tag(RuleAction.block)
                        Text(RuleText.action(.allow)).tag(RuleAction.allow)
                    }
                    .pickerStyle(.segmented)

                    Picker("Nerede aransın", selection: $target) {
                        Text(RuleText.target(.body)).tag(RuleTarget.body)
                        Text(RuleText.target(.sender)).tag(RuleTarget.sender)
                    }
                    .pickerStyle(.segmented)

                    Picker("Nasıl eşleşsin", selection: $mode) {
                        Text(RuleText.mode(.contains)).tag(MatchMode.contains)
                        Text(RuleText.mode(.wholeWord)).tag(MatchMode.wholeWord)
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text("Tam kelime: \"icra\" yazarsanız \"icra\" kelimesini bulur, \"ticaret\" içindekini bulmaz.")
                        .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.surface)

                Section {
                    Button("Kaydet") { submit() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .foregroundStyle(Theme.text)
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Kural ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                        .foregroundStyle(Theme.text)
                }
            }
            .onAppear { patternFocused = true }
        }
    }

    private func submit() {
        if let message = store.addRule(pattern: pattern, target: target, mode: mode, action: action) {
            errorText = message
        } else {
            dismiss()
        }
    }
}

/// Type or paste a message and see what Sessiz would do and why.
struct TestMessageView: View {
    @ObservedObject var store: RuleStore
    @State private var sender = ""
    @State private var message = ""

    private var hasMessage: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var verdict: Verdict {
        store.classifier.classify(sender: sender.isEmpty ? nil : sender, body: message)
    }

    var body: some View {
        Form {
            Section {
                TextField("Gönderen (isteğe bağlı)", text: $sender)
                    .autocorrectionDisabled()
                TextField("Mesaj metni", text: $message, axis: .vertical)
                    .lineLimit(3...8)
            }
            .listRowBackground(Theme.surface)

            Section {
                if hasMessage {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(verdict.isSpam ? "Engellenir" : "Geçer")
                            .font(.headline)
                            .foregroundStyle(Theme.text)
                        Text(verdict.explanation)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .accessibilityElement(children: .combine)
                } else {
                    Text("Sonuç burada görünür.").foregroundStyle(Theme.secondaryText)
                }
            } header: {
                Text("Sonuç").foregroundStyle(Theme.secondaryText)
            } footer: {
                Text("Bu bir deneme. Gerçek mesajlarınıza dokunulmaz.")
                    .foregroundStyle(Theme.secondaryText)
            }
            .listRowBackground(Theme.surface)
        }
        .foregroundStyle(Theme.text)
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Test et")
        .navigationBarTitleDisplayMode(.inline)
    }
}
