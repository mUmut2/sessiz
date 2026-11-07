import SpamCore
import SwiftUI

struct NumbersView: View {
    @StateObject private var store = BlocklistStore()
    @State private var query = ""
    @State private var showingAdd = false

    private var visible: [BlockedNumber] { store.blocklist.filtered(by: query) }

    var body: some View {
        NavigationStack {
            Group {
                if store.blocklist.entries.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) { AdBannerSlot() }
            .navigationTitle("Numaralar")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink("Hazır liste") { ProtectionView(store: store) }
                        .foregroundStyle(Theme.text)
                }
                if !store.blocklist.entries.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Ekle") { showingAdd = true }
                            .foregroundStyle(Theme.text)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddNumberSheet(store: store)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.s) {
            Text("Engellenen numara yok.")
                .foregroundStyle(Theme.secondaryText)
            Button("Numara ekle") { showingAdd = true }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 280)
        }
        .padding(Theme.Spacing.m)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        List {
            Section {
                ForEach(visible) { item in
                    NumberRow(item: item)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.remove(item)
                            } label: {
                                Text("Sil")
                            }
                        }
                }
            } footer: {
                if let problem = store.problem {
                    Text(problem).foregroundStyle(Theme.text)
                } else if visible.isEmpty {
                    Text("Eşleşen numara yok.").foregroundStyle(Theme.secondaryText)
                }
            }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .searchable(text: $query, prompt: "Numara veya not ara")
    }
}

private struct NumberRow: View {
    let item: BlockedNumber

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(PhoneFormatter.display(item.e164))
                .foregroundStyle(Theme.text)
            if !item.label.isEmpty {
                Text(item.label)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct AddNumberSheet: View {
    @ObservedObject var store: BlocklistStore
    @Environment(\.dismiss) private var dismiss
    @State private var number = ""
    @State private var label = ""
    @State private var errorText: String?
    @FocusState private var numberFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Numara", text: $number)
                        .keyboardType(.phonePad)
                        .focused($numberFocused)
                        .accessibilityLabel("Engellenecek numara")
                    TextField("Not (isteğe bağlı)", text: $label)
                } footer: {
                    if let errorText {
                        Text(errorText).foregroundStyle(Theme.text)
                    } else {
                        Text("Örnek: 0555 123 45 67 veya +90 850 123 45 67").foregroundStyle(Theme.secondaryText)
                    }
                }
                .listRowBackground(Theme.surface)

                Section {
                    Button("Engelle") { submit() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .foregroundStyle(Theme.text)
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Numara ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                        .foregroundStyle(Theme.text)
                }
            }
            .onAppear { numberFocused = true }
        }
    }

    private func submit() {
        if let message = store.add(input: number, label: label) {
            errorText = message
        } else {
            dismiss()
        }
    }
}
