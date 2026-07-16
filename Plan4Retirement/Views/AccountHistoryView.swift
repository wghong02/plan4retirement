import SwiftUI

struct AccountHistoryView: View {
    let account: Account
    @Binding var isPresented: Bool

    @State private var history: [AccountHistory] = []
    private let historyService = AccountHistoryService()

    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)
                        Text("No History")
                            .font(.headline)
                        Text("Balance updates for this account will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(history) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(entry.updateDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                    Spacer()
                                    Text(entry.actualBalance.formatted(as: true))
                                        .font(.headline)
                                }

                                if let notes = entry.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 2)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("\(account.name) History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        do {
            history = try historyService.getHistoryForAccount(accountId: account.id)
        } catch {
            print("Error loading history: \(error)")
        }
    }

    private func delete(_ entry: AccountHistory) {
        do {
            try historyService.deleteHistoryEntry(by: entry.id)
        } catch {
            print("Error deleting history entry: \(error)")
        }
        history.removeAll { $0.id == entry.id }
    }
}

#Preview {
    AccountHistoryView(
        account: Account(name: "401(k)", type: .preTax, currentBalance: 100000, annualContribution: 10000, expectedROI: 7.0),
        isPresented: .constant(true)
    )
}
