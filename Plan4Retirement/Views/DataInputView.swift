import SwiftUI

struct DataInputView: View {
    @State private var accounts: [Account] = []
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
        case updateBalance(Account)
        case history(Account)

        var id: String {
            switch self {
            case .add: return "add"
            case .updateBalance(let account): return "update-\(account.id)"
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
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(account.name)
                                            .font(.headline)
                                        Text(account.type.displayName)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing) {
                                        Text(account.currentBalance.formatted(as: true))
                                            .font(.headline)
                                        Text(account.expectedROI.formatted(as: false) + "% ROI")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
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
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .add:
                    AddAccountView(isPresented: sheetPresented) { newAccount in
                        do {
                            try accountService.addAccount(newAccount)
                            loadAccounts()
                        } catch {
                            print("Error adding account: \(error)")
                        }
                    }

                case .updateBalance(let account):
                    UpdateBalanceView(account: account, isPresented: sheetPresented) { actualBalance, date, notes in
                        do {
                            // Record the change in history, keeping the prior balance as the "projected" value.
                            let entry = AccountHistory(
                                accountId: account.id,
                                actualBalance: actualBalance,
                                projectedBalance: account.currentBalance,
                                updateDate: date,
                                notes: notes
                            )
                            try historyService.addHistoryEntry(entry)

                            // Update the account's current balance to the new value.
                            var updated = account
                            updated.currentBalance = actualBalance
                            try accountService.updateAccount(updated)

                            loadAccounts()
                        } catch {
                            print("Error updating balance: \(error)")
                        }
                    }

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
        } catch {
            print("Error loading accounts: \(error)")
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
