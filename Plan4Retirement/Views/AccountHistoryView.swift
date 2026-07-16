import SwiftUI

struct AccountHistoryView: View {
    let account: Account
    @Binding var isPresented: Bool

    @State private var history: [AccountHistory] = []
    @State private var editingEntry: AccountHistory?
    private let historyService = AccountHistoryService()
    private let accountService = AccountService()

    private var editSheetPresented: Binding<Bool> {
        Binding(get: { editingEntry != nil }, set: { if !$0 { editingEntry = nil } })
    }

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
                                    Text(entry.updateDate.formatted(date: .abbreviated, time: .omitted))
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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingEntry = entry
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                // Keep at least one entry so the account always has a baseline balance.
                                if history.count > 1 {
                                    Button(role: .destructive) {
                                        delete(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
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
            .sheet(item: $editingEntry) { entry in
                UpdateBalanceView(
                    account: account,
                    existingEntry: entry,
                    isPresented: editSheetPresented,
                    onSave: { balance, date, notes in
                        update(entry, balance: balance, date: date, notes: notes)
                    },
                    // Deletion is only offered when it won't remove the last entry.
                    onDelete: history.count > 1 ? {
                        delete(entry)
                        editingEntry = nil
                    } : nil,
                    duplicateCheck: { balance, date, notes in
                        history.contains { other in
                            other.id != entry.id
                                && other.actualBalance == balance
                                && Calendar.current.isDate(other.updateDate, inSameDayAs: date)
                                && (other.notes ?? "") == (notes ?? "")
                        }
                    }
                )
            }
        }
    }

    private func load() {
        do {
            history = try historyService.getHistoryForAccount(accountId: account.id)
        } catch {
            print("Error loading history: \(error)")
        }
    }

    private func update(_ entry: AccountHistory, balance: Double, date: Date, notes: String?) {
        let updated = AccountHistory(
            id: entry.id,
            accountId: entry.accountId,
            actualBalance: balance,
            projectedBalance: entry.projectedBalance,
            updateDate: date,
            notes: notes
        )
        do {
            try historyService.updateHistoryEntry(updated)
            try accountService.syncCurrentBalanceFromHistory(accountId: account.id)
        } catch {
            print("Error updating history entry: \(error)")
        }
        load()
    }

    private func delete(_ entry: AccountHistory) {
        // Never remove the last remaining entry.
        guard history.count > 1 else { return }
        do {
            try historyService.deleteHistoryEntry(by: entry.id)
            try accountService.syncCurrentBalanceFromHistory(accountId: account.id)
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
