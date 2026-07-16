import SwiftUI

struct DataInputView: View {
    @State private var accounts: [Account] = []
    @State private var lastUpdateDates: [String: Date] = [:]
    @State private var activeSheet: ActiveSheet?
    @State private var accountToDelete: Account?
    @State private var showDeleteConfirmation = false

    private let accountService = AccountService()
    private let historyService = AccountHistoryService()
    private let snapshotService = ProjectionSnapshotService()

    /// A single item-driven sheet avoids the `.sheet(isPresented:)` race where the
    /// selected account isn't ready when the sheet content is first built.
    private enum ActiveSheet: Identifiable {
        case add
        case updateDetails(Account)
        case updateBalance(Account)
        case history(Account)

        var id: String {
            switch self {
            case .add: return "add"
            case .updateDetails(let account): return "details-\(account.id)"
            case .updateBalance(let account): return "balance-\(account.id)"
            case .history(let account): return "history-\(account.id)"
            }
        }
    }

    private var sheetPresented: Binding<Bool> {
        Binding(get: { activeSheet != nil }, set: { if !$0 { activeSheet = nil } })
    }

    var body: some View {
        NavigationStack {
            VStack {
                if accounts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "inbox.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)

                        Text("No Accounts")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Text("Add your first retirement account to get started")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        ForEach(accounts) { account in
                            VStack(alignment: .leading, spacing: 8) {
                                // Tapping the account info opens the details editor.
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(account.name)
                                            .font(.headline)
                                        Text(account.type.displayName)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        if let updated = lastUpdateDates[account.id] {
                                            Text("Updated \(updated.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing) {
                                        Text(account.currentBalance.formatted(as: true))
                                            .font(.headline)
                                        Text(account.expectedROI.formatted(as: false) + "% ROI")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    activeSheet = .updateDetails(account)
                                }

                                HStack(spacing: 12) {
                                    Button(action: {
                                        activeSheet = .updateBalance(account)
                                    }) {
                                        Label("Update Balance", systemImage: "arrow.up.circle")
                                            .font(.subheadline)
                                    }
                                    .buttonStyle(.borderless)

                                    Button(action: {
                                        activeSheet = .history(account)
                                    }) {
                                        Label("History", systemImage: "clock.fill")
                                            .font(.subheadline)
                                    }
                                    .buttonStyle(.borderless)

                                    Spacer()
                                }
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    accountToDelete = account
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }

                HStack(spacing: 12) {
                    Button(action: { activeSheet = .add }) {
                        Label("Add Account", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(accounts.count >= 5)
                }
                .padding()
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadAccounts)
            .sheet(item: $activeSheet, onDismiss: loadAccounts) { sheet in
                switch sheet {
                case .add:
                    AddAccountView(isPresented: sheetPresented) { newAccount in
                        do {
                            try accountService.addAccount(newAccount)
                            // Seed history with the initial balance so every account has a baseline entry.
                            let initial = AccountHistory(
                                accountId: newAccount.id,
                                actualBalance: newAccount.currentBalance,
                                projectedBalance: newAccount.currentBalance,
                                updateDate: Calendar.current.startOfDay(for: newAccount.createdDate),
                                notes: "Initial balance"
                            )
                            try historyService.addHistoryEntry(initial)
                            loadAccounts()
                        } catch {
                            print("Error adding account: \(error)")
                        }
                    }

                case .updateDetails(let account):
                    UpdateDetailsView(account: account, isPresented: sheetPresented) { updated in
                        do {
                            try accountService.updateAccount(updated)
                            loadAccounts()
                        } catch {
                            print("Error updating account details: \(error)")
                        }
                    }

                case .updateBalance(let account):
                    UpdateBalanceView(
                        account: account,
                        isPresented: sheetPresented,
                        onSave: { balance, date, notes in
                            do {
                                let entry = AccountHistory(
                                    accountId: account.id,
                                    actualBalance: balance,
                                    projectedBalance: account.currentBalance,
                                    updateDate: date,
                                    notes: notes
                                )
                                try historyService.addHistoryEntry(entry)
                                try accountService.syncCurrentBalanceFromHistory(accountId: account.id)
                                loadAccounts()
                            } catch {
                                print("Error updating balance: \(error)")
                            }
                        },
                        duplicateCheck: { balance, date, notes in
                            isDuplicateHistory(accountId: account.id, balance: balance, date: date, notes: notes)
                        }
                    )

                case .history(let account):
                    AccountHistoryView(account: account, isPresented: sheetPresented)
                }
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirmation, presenting: accountToDelete) { account in
                Button("Delete", role: .destructive) {
                    deleteAccount(account)
                }
                Button("Cancel", role: .cancel) { }
            } message: { account in
                Text("This will permanently delete \"\(account.name)\", its balance history, and all saved projections. This action cannot be undone.")
            }
        }
    }

    private func loadAccounts() {
        do {
            accounts = try accountService.getAllAccounts()

            // Latest balance-update date per account (the most recent history entry).
            var dates: [String: Date] = [:]
            for account in accounts {
                if let latest = try? historyService.getLatestHistoryEntry(for: account.id) {
                    dates[account.id] = latest.updateDate
                }
            }
            lastUpdateDates = dates
        } catch {
            print("Error loading accounts: \(error)")
        }
    }

    /// True when a history entry with the same balance, day, and note already exists.
    private func isDuplicateHistory(accountId: String, balance: Double, date: Date, notes: String?) -> Bool {
        let existing = (try? historyService.getHistoryForAccount(accountId: accountId)) ?? []
        return existing.contains { entry in
            entry.actualBalance == balance
                && Calendar.current.isDate(entry.updateDate, inSameDayAs: date)
                && (entry.notes ?? "") == (notes ?? "")
        }
    }

    private func deleteAccount(_ account: Account) {
        // Removes the account and its balance history.
        do {
            try accountService.deleteAccount(by: account.id)
        } catch {
            print("Error deleting account: \(error)")
        }

        // Saved projections were computed from the old portfolio, so clear them.
        // Kept separate so a snapshot failure can't block the account removal / UI refresh.
        do {
            try snapshotService.deleteAllSnapshots()
        } catch {
            print("Error clearing snapshots: \(error)")
        }

        // Drop the row immediately, then reconcile with the store.
        accounts.removeAll { $0.id == account.id }
        loadAccounts()
    }
}

#Preview {
    DataInputView()
}
