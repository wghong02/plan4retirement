import SwiftUI

struct DataInputView: View {
    @State private var accounts: [Account] = []
    @State private var showAddAccountSheet = false
    @State private var showUpdateBalanceSheet = false
    @State private var selectedAccount: Account?
    @State private var accountHistory: [AccountHistory] = []

    private let accountService = AccountService()
    private let historyService = AccountHistoryService()

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
                                        selectedAccount = account
                                        showUpdateBalanceSheet = true
                                    }) {
                                        Label("Update Balance", systemImage: "arrow.up.circle")
                                            .font(.subheadline)
                                    }
                                    .buttonStyle(.bordered)

                                    Button(action: {
                                        selectedAccount = account
                                        loadAccountHistory()
                                    }) {
                                        Label("History", systemImage: "clock.fill")
                                            .font(.subheadline)
                                    }
                                    .buttonStyle(.bordered)

                                    Spacer()
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteAccount)
                    }
                    .listStyle(.plain)
                }

                HStack(spacing: 12) {
                    Button(action: { showAddAccountSheet = true }) {
                        Label("Add Account", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(accounts.count >= 5)
                }
                .padding()
            }
            .navigationTitle("Accounts")
            .onAppear(perform: loadAccounts)
            .sheet(isPresented: $showAddAccountSheet) {
                AddAccountView(isPresented: $showAddAccountSheet) { newAccount in
                    do {
                        try accountService.addAccount(newAccount)
                        loadAccounts()
                    } catch {
                        print("Error adding account: \(error)")
                    }
                }
            }
            .sheet(isPresented: $showUpdateBalanceSheet) {
                if let account = selectedAccount {
                    UpdateBalanceView(account: account, isPresented: $showUpdateBalanceSheet) { actualBalance in
                        do {
                            let entry = AccountHistory(
                                accountId: account.id,
                                actualBalance: actualBalance,
                                projectedBalance: account.currentBalance
                            )
                            try historyService.addHistoryEntry(entry)
                            loadAccounts()
                        } catch {
                            print("Error updating balance: \(error)")
                        }
                    }
                }
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

    private func deleteAccount(at offsets: IndexSet) {
        for index in offsets {
            let account = accounts[index]
            do {
                try accountService.deleteAccount(by: account.id)
                loadAccounts()
            } catch {
                print("Error deleting account: \(error)")
            }
        }
    }

    private func loadAccountHistory() {
        guard let account = selectedAccount else { return }
        do {
            accountHistory = try historyService.getHistoryForAccount(accountId: account.id)
        } catch {
            print("Error loading history: \(error)")
        }
    }
}

#Preview {
    DataInputView()
}
