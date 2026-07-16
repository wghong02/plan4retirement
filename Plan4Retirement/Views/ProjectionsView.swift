import Foundation
import SwiftUI

struct ProjectionsView: View {
    @EnvironmentObject var settings: SettingsService
    @State private var accounts: [Account] = []
    @State private var projection: (projectionDataPoints: [ProjectionDataPoint], projectedBalance: Double)? = nil
    @State private var parameters: ProjectionParameters? = nil
    @State private var actualSeries: [ProjectionDataPoint] = []
    @State private var savedSnapshots: [ProjectionSnapshot] = []
    @State private var showSaveSnapshot = false
    @State private var filterMode: FilterMode = .current
    @State private var selectedSnapshotId: String? = nil
    @State private var chartMode: RetirementLineChart.DisplayMode = .yearly
    @State private var savedChartMode: RetirementLineChart.DisplayMode = .yearly

    private let accountService = AccountService()
    private let calculator = ProjectionCalculator()
    private let lifeEventService = LifeEventService()
    private let snapshotService = ProjectionSnapshotService()
    private let historyService = AccountHistoryService()

    enum FilterMode {
        case current
        case saved
        case byAccount
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter tabs
                Picker("View", selection: $filterMode) {
                    Text("Current").tag(FilterMode.current)
                    Text("Saved").tag(FilterMode.saved)
                    Text("Breakdown").tag(FilterMode.byAccount)
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    VStack(spacing: 16) {
                        // Charts section
                        if !accounts.isEmpty {
                            switch filterMode {
                            case .current:
                                currentProjectionView()

                            case .saved:
                                savedProjectionsView()

                            case .byAccount:
                                accountDistributionView()
                            }
                        } else {
                            emptyStateView()
                        }

                        // Save snapshot button
                        if filterMode == .current && !accounts.isEmpty {
                            Button(action: { showSaveSnapshot = true }) {
                                Label("Save Current Projection", systemImage: "square.and.arrow.down")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                        }

                        // Saved snapshots list
                        if !savedSnapshots.isEmpty {
                            savedSnapshotsListSection()
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Projections")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadData)
            .onReceive(settings.$maxYearsDisplayed) { _ in loadData() }
            .onReceive(settings.$maxMonthsDisplayed) { _ in loadData() }
            .sheet(isPresented: $showSaveSnapshot) {
                SaveSnapshotView(isPresented: $showSaveSnapshot) { snapshotName in
                    saveSnapshot(name: snapshotName)
                }
            }
        }
    }

    // MARK: - Current Projection View
    @ViewBuilder
    private func currentProjectionView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let projection, let parameters {
                RetirementLineChart(
                    dataPoints: projection.projectionDataPoints,
                    actualDataPoints: actualSeries,
                    title: "Retirement Growth Projection",
                    maxMonths: settings.maxMonthsDisplayed,
                    maxYears: settings.maxYearsDisplayed,
                    inflationAdjusted: settings.showInflationAdjusted,
                    inflationRate: parameters.inflationRate,
                    displayMode: $chartMode
                )
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Projected Balance at \(parameters.retirementAge)\(todaysDollarsSuffix)")
                            .font(.subheadline)
                        Spacer()
                        Text(todaysDollars(projection.projectedBalance,
                                           yearsFromNow: parameters.retirementAge - parameters.currentAge,
                                           inflationRate: parameters.inflationRate).formatted(as: true))
                            .font(.headline)
                    }

                    HStack {
                        Text("\(rateLabelPrefix) Avg Growth Rate")
                            .font(.subheadline)
                        Spacer()
                        Text(periodRate(weightedRate(\.expectedROI)).formattedAsPercentage())
                            .font(.subheadline)
                    }

                    HStack {
                        Text("\(rateLabelPrefix) Inflation Rate")
                            .font(.subheadline)
                        Spacer()
                        Text(periodRate(parameters.inflationRate).formattedAsPercentage())
                            .font(.subheadline)
                    }

                    HStack {
                        Text("\(rateLabelPrefix) Avg Contribution Increase")
                            .font(.subheadline)
                        Spacer()
                        Text(periodRate(weightedRate(\.contributionIncreaseRate)).formattedAsPercentage())
                            .font(.subheadline)
                    }
                }
                .cardStyle(cornerRadius: 8)
            }
        }
    }

    // MARK: - Saved Projections View
    @ViewBuilder
    private func savedProjectionsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if savedSnapshots.isEmpty {
                emptyStateView()
            } else {
                // Snapshot selector
                Menu {
                    ForEach(savedSnapshots.sorted { $0.createdDate > $1.createdDate }) { snapshot in
                        Button(action: { selectedSnapshotId = snapshot.id }) {
                            HStack {
                                Text(snapshot.name)
                                if selectedSnapshotId == snapshot.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedSnapshotLabel)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .cardStyle(cornerRadius: 8)
                }

                if let snapshot = savedSnapshots.first(where: { $0.id == selectedSnapshotId }) {
                    RetirementLineChart(
                        dataPoints: snapshot.projectionData,
                        title: "Projection: \(snapshot.name)",
                        startYear: Calendar.current.component(.year, from: snapshot.createdDate),
                        startMonth: Calendar.current.component(.month, from: snapshot.createdDate),
                        maxMonths: settings.maxMonthsDisplayed,
                        maxYears: settings.maxYearsDisplayed,
                        inflationAdjusted: settings.showInflationAdjusted,
                        inflationRate: snapshot.parametersUsed.inflationRate,
                        displayMode: $savedChartMode
                    )
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Projected Balance at \(snapshot.projectedRetirementAge)\(todaysDollarsSuffix)")
                                .font(.subheadline)
                            Spacer()
                            Text(todaysDollars(snapshot.projectedBalance,
                                               yearsFromNow: snapshot.projectedRetirementAge - snapshot.parametersUsed.currentAge,
                                               inflationRate: snapshot.parametersUsed.inflationRate).formatted(as: true))
                                .font(.headline)
                        }

                        HStack {
                            Text("Saved")
                                .font(.subheadline)
                            Spacer()
                            Text(snapshot.createdDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .cardStyle(cornerRadius: 8)
                }
            }
        }
    }

    // MARK: - Account Distribution View
    @ViewBuilder
    private func accountDistributionView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Distribution")
                .font(.headline)
                .padding(.horizontal)

            let distribution = calculator.analyzeAccountDistribution(accounts: accounts)

            AccountDistributionHistogram(
                distribution: distribution.distribution,
                title: "Balance by Tax Treatment"
            )
            .cardStyle()

            VStack(alignment: .leading, spacing: 8) {
                Text("Total Assets: \(distribution.totalBalance.formatted(as: true))")
                    .font(.headline)

                Divider()

                ForEach(Array(distribution.percentageDistribution.sorted { $0.key < $1.key }), id: \.key) { key, percentage in
                    HStack {
                        Text(key)
                            .font(.subheadline)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f%%", percentage))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(distribution.distribution[key] ?? 0, format: .currency(code: "USD"))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .cardStyle(cornerRadius: 8)
        }
    }

    // MARK: - Saved Snapshots List Section
    @ViewBuilder
    private func savedSnapshotsListSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Saved Snapshots")
                .font(.headline)

            ForEach(savedSnapshots.sorted { $0.createdDate > $1.createdDate }) { snapshot in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(snapshot.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(snapshot.createdDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(snapshot.projectedBalance.formatted(as: true))
                                .font(.headline)
                            Text("age \(snapshot.projectedRetirementAge)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .cardStyle(cornerRadius: 8)
            }
        }
        .padding()
        .background(Color(.systemGray5).opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Empty State
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("No Projections")
                .font(.headline)
            Text("Add accounts to see retirement projections")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Computed Properties
    /// "Monthly" or "Annual" depending on the current chart's display mode.
    private var rateLabelPrefix: String {
        chartMode == .monthly ? "Monthly" : "Annual"
    }

    /// Suffix appended to balance labels when amounts are shown in today's dollars.
    private var todaysDollarsSuffix: String {
        settings.showInflationAdjusted ? " (today's $)" : ""
    }

    /// Balance-weighted average of a per-account rate (e.g. ROI or contribution increase).
    private func weightedRate(_ keyPath: KeyPath<Account, Double>) -> Double {
        let total = accounts.totalBalance
        guard total > 0 else {
            guard !accounts.isEmpty else { return 0 }
            return accounts.reduce(0) { $0 + $1[keyPath: keyPath] } / Double(accounts.count)
        }
        return accounts.reduce(0) { $0 + $1[keyPath: keyPath] * ($1.currentBalance / total) }
    }

    /// Deflates a future amount to today's dollars when the setting is on.
    private func todaysDollars(_ amount: Double, yearsFromNow: Int, inflationRate: Double) -> Double {
        guard settings.showInflationAdjusted, inflationRate != 0 else { return amount }
        return amount / pow(1 + inflationRate / 100.0, Double(yearsFromNow))
    }

    /// Converts an annual percentage rate to its monthly-compounding equivalent
    /// when the chart is in monthly mode.
    private func periodRate(_ annualPercent: Double) -> Double {
        switch chartMode {
        case .yearly:
            return annualPercent
        case .monthly:
            return (pow(1 + annualPercent / 100.0, 1.0 / 12.0) - 1) * 100.0
        }
    }

    private var selectedSnapshotLabel: String {
        if let id = selectedSnapshotId,
           let snapshot = savedSnapshots.first(where: { $0.id == id }) {
            return snapshot.name
        }
        return savedSnapshots.first?.name ?? "Select Projection"
    }

    /// Aggregates recorded account balances into a monthly total series over the past,
    /// using each account's latest history entry as of each month. monthIndex is 0 at
    /// the current month and negative for earlier months.
    private func buildActualSeries(accounts: [Account], histories: [String: [AccountHistory]], currentAge: Int) -> [ProjectionDataPoint] {
        let cal = Calendar.current
        let now = Date()
        let nowMonths = cal.component(.year, from: now) * 12 + (cal.component(.month, from: now) - 1)

        func monthOffset(_ date: Date) -> Int {
            let m = cal.component(.year, from: date) * 12 + (cal.component(.month, from: date) - 1)
            return m - nowMonths
        }

        // Earliest recorded month across all accounts (0 or negative).
        var earliest = 0
        for entries in histories.values {
            for entry in entries {
                earliest = min(earliest, monthOffset(entry.updateDate))
            }
        }
        guard earliest < 0 else { return [] } // no past history to show

        var series: [ProjectionDataPoint] = []
        for month in stride(from: earliest, through: 0, by: 1) {
            var total = 0.0
            for account in accounts {
                // Histories are sorted newest-first; take the latest entry on or before this month.
                if let latest = histories[account.id]?.first(where: { monthOffset($0.updateDate) <= month }) {
                    total += latest.actualBalance
                }
            }
            let year = Int(floor(Double(month) / 12.0))
            series.append(ProjectionDataPoint(monthIndex: month, age: currentAge + year, balance: total, contribution: 0, growth: 0))
        }
        return series
    }

    // MARK: - Data Loading
    private func loadData() {
        do {
            accounts = try accountService.getAllAccounts()
            savedSnapshots = try snapshotService.getAllSnapshots()

            let lifeEvents = try lifeEventService.getAllLifeEvents()
            let params = settings.getProjectionParameters(lifeEvents: lifeEvents)

            parameters = params
            // Project far enough to cover whichever display window is larger.
            let horizonMonths = max(settings.maxYearsDisplayed * 12, settings.maxMonthsDisplayed)
            projection = calculator.calculateRetirementProjection(
                accounts: accounts,
                parameters: params,
                horizonMonths: horizonMonths
            )

            // Actual recorded balances (past) to overlay on the projection.
            var historiesByAccount: [String: [AccountHistory]] = [:]
            for account in accounts {
                historiesByAccount[account.id] = (try? historyService.getHistoryForAccount(accountId: account.id)) ?? []
            }
            actualSeries = buildActualSeries(accounts: accounts, histories: historiesByAccount, currentAge: params.currentAge)

            // Set default selected snapshot
            if selectedSnapshotId == nil, let first = savedSnapshots.first {
                selectedSnapshotId = first.id
            }
        } catch {
            print("Error loading projections: \(error)")
        }
    }

    private func saveSnapshot(name: String) {
        do {
            guard let projection, let parameters else { return }

            let snapshot = ProjectionSnapshot(
                name: name,
                projectedRetirementAge: parameters.retirementAge,
                projectedBalance: projection.projectedBalance,
                projectionData: projection.projectionDataPoints,
                parametersUsed: parameters
            )

            // Honor the user-configured retention limit.
            snapshotService.setMaxSnapshots(settings.maxProjectionSnapshots)
            try snapshotService.saveSnapshot(snapshot)
            loadData()
        } catch {
            print("Error saving snapshot: \(error)")
        }
    }
}

#Preview {
    ProjectionsView()
        .environmentObject(SettingsService.shared)
}
