import SwiftUI

struct AccountHistoryView: View {
    let account: Account
    let history: [AccountHistory]
    @Binding var isPresented: Bool

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
                    List(history) { entry in
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
        }
    }
}

#Preview {
    AccountHistoryView(
        account: Account(name: "401(k)", type: .preTax, currentBalance: 100000, annualContribution: 10000, expectedROI: 7.0),
        history: [],
        isPresented: .constant(true)
    )
}
