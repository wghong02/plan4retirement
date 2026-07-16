import Foundation
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var settings: SettingsService
    @State private var accounts: [Account] = []
    @State private var projectionResult: (projectionDataPoints: [ProjectionDataPoint], projectedBalance: Double)? = nil

    private let accountService = AccountService()
    private let calculator = ProjectionCalculator()
    private let lifeEventService = LifeEventService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if accounts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No Accounts")
                                .font(.headline)
                            Text("Add accounts in the Data Input tab to see projections")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                    } else {
                        // Total Current Assets Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Current Assets")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text(totalAssets.formatted(as: true))
                                .font(.title)
                                .fontWeight(.bold)

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Accounts: \(accounts.count)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("Avg ROI: \(averageROI.formatted(as: false))%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Total Contributions")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(totalContributions.formatted(as: true))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .cardStyle()

                        // Projected Retirement Card
                        if let result = projectionResult {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("At Retirement (\(settings.retirementAge))\(settings.showInflationAdjusted ? " · today's $" : "")")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                Text(retirementBalance(result.projectedBalance).formatted(as: true))
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle()
                        }

                        // Account Breakdown
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Account Breakdown")
                                .font(.headline)

                            ForEach(accounts) { account in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(account.name)
                                            .font(.subheadline)
                                        Text(account.type.displayName)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(account.currentBalance.formatted(as: true))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("\(account.expectedROI.formatted(as: false))% ROI")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .cardStyle()

                        Spacer()
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadData)
            .onReceive(settings.$currentAge) { _ in loadData() }
            .onReceive(settings.$retirementAge) { _ in loadData() }
            .onReceive(settings.$inflationRate) { _ in loadData() }
            .onReceive(settings.$annualSpendingInRetirement) { _ in loadData() }
            .onReceive(settings.$lifeExpectancy) { _ in loadData() }
        }
    }

    private var totalAssets: Double {
        accounts.totalBalance
    }

    private var totalContributions: Double {
        accounts.reduce(0) { $0 + $1.annualContribution }
    }

    /// Deflates the projected retirement balance to today's dollars when the setting is on.
    private func retirementBalance(_ amount: Double) -> Double {
        guard settings.showInflationAdjusted, settings.inflationRate != 0 else { return amount }
        let years = max(0, settings.retirementAge - settings.currentAge)
        return amount / pow(1 + settings.inflationRate / 100.0, Double(years))
    }

    /// ROI weighted by each account's most recent balance.
    private var averageROI: Double {
        let total = accounts.totalBalance
        guard total > 0 else { return 0 }
        return accounts.reduce(0) { $0 + $1.expectedROI * ($1.currentBalance / total) }
    }

    private func loadData() {
        do {
            accounts = try accountService.getAllAccounts()

            let lifeEvents = try lifeEventService.getAllLifeEvents()
            let params = settings.getProjectionParameters(lifeEvents: lifeEvents)

            projectionResult = calculator.calculateRetirementProjection(
                accounts: accounts,
                parameters: params
            )
        } catch {
            print("Error loading data: \(error)")
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(SettingsService.shared)
}
