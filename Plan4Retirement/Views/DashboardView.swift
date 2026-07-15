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
                        // Total Assets Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Assets")
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
                                    Text("Age: \(settings.currentAge)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("Retirement: \(settings.retirementAge)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .cardStyle()

                        // Projected Retirement Card
                        if let result = projectionResult {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("At Retirement (\(settings.retirementAge))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                Text(result.projectedBalance.formatted(as: true))
                                    .font(.title)
                                    .fontWeight(.bold)

                                HStack {
                                    Label(
                                        "\(result.projectionDataPoints.count) years of projections",
                                        systemImage: "calendar"
                                    )
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                    Spacer()
                                }
                            }
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
            .onAppear(perform: loadData)
            .onReceive(settings.$currentAge) { _ in loadData() }
            .onReceive(settings.$retirementAge) { _ in loadData() }
            .onReceive(settings.$inflationRate) { _ in loadData() }
            .onReceive(settings.$assetGrowthRate) { _ in loadData() }
        }
    }

    private var totalAssets: Double {
        accounts.totalBalance
    }

    private var averageROI: Double {
        guard !accounts.isEmpty else { return 0 }
        return accounts.reduce(0) { $0 + $1.expectedROI } / Double(accounts.count)
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
