import Foundation

/// Output of a retirement projection: the full monthly series plus the balance
/// at retirement age.
struct ProjectionResult {
    let dataPoints: [ProjectionDataPoint]
    let projectedBalance: Double
}

class ProjectionCalculator {

    // MARK: - Main Projection Calculation
    /// Projects balances month by month across the full horizon. Yearly views are
    /// derived by sampling one point per year (see `RetirementLineChart`).
    /// - Parameter horizonMonths: optional minimum number of months to project,
    ///   so the graph can display the full window configured in Settings even
    ///   when it extends past life expectancy.
    func calculateRetirementProjection(
        accounts: [Account],
        parameters: ProjectionParameters,
        horizonMonths: Int? = nil
    ) -> ProjectionResult {

        var dataPoints: [ProjectionDataPoint] = []

        // Each account grows and contributes at its own rate; the total is the sum.
        var balances = accounts.map(\.currentBalance)
        let monthlyGrowth = accounts.map { pow(1 + $0.expectedROI / 100.0, 1.0 / 12.0) - 1 }
        let baseContribution = accounts.map(\.annualContribution)
        let contributionIncrease = accounts.map { $0.contributionIncreaseRate / 100.0 }
        let inflationRate = parameters.inflationRate / 100.0

        let lifeHorizon = max(0, parameters.lifeExpectancy - parameters.currentAge) * 12
        let totalMonths = max(lifeHorizon, horizonMonths ?? 0)

        // Month 0 is the starting point: exactly the current balance, with no growth
        // or contribution applied yet.
        dataPoints.append(ProjectionDataPoint(
            monthIndex: 0,
            age: parameters.currentAge,
            balance: balances.reduce(0, +),
            contribution: 0,
            growth: 0
        ))

        if totalMonths >= 1 {
            for month in 1...totalMonths {
                let year = month / 12
                let age = parameters.currentAge + year
                let working = age < parameters.retirementAge

                var monthGrowth = 0.0
                var monthContribution = 0.0

                // Grow and contribute per account.
                for i in accounts.indices {
                    let before = balances[i]
                    balances[i] *= (1 + monthlyGrowth[i])
                    monthGrowth += before * monthlyGrowth[i]

                    if working {
                        let annual = baseContribution[i] * pow(1 + contributionIncrease[i], Double(year))
                        let monthly = annual / 12.0
                        balances[i] += monthly
                        monthContribution += monthly
                    }
                }

                // Retirement drawdown (inflation-adjusted), allocated across accounts by balance.
                if !working {
                    let spending = parameters.annualSpendingInRetirement * pow(1 + inflationRate, Double(year)) / 12.0
                    allocate(-spending, across: &balances)
                }

                // One-off life events for this month, allocated across accounts by balance.
                for event in lifeEvents(parameters.lifeEvents, inMonth: month) {
                    switch event.type {
                    case .housePurchase, .carPurchase, .majorExpense, .medicalExpense:
                        allocate(-event.amount, across: &balances)
                    case .inheritance:
                        allocate(event.amount, across: &balances)
                    case .other:
                        break
                    }
                }

                for i in balances.indices {
                    balances[i] = max(0, balances[i])
                }

                dataPoints.append(ProjectionDataPoint(
                    monthIndex: month,
                    age: age,
                    balance: balances.reduce(0, +),
                    contribution: monthContribution,
                    growth: monthGrowth
                ))
            }
        }

        let projectedBalance = dataPoints.first { $0.age >= parameters.retirementAge }?.balance
            ?? dataPoints.last?.balance ?? balances.reduce(0, +)

        return ProjectionResult(dataPoints: dataPoints, projectedBalance: projectedBalance)
    }

    /// Distributes a household-level amount (positive or negative) across account
    /// balances in proportion to their size. Falls back to the first account when
    /// the total is zero.
    private func allocate(_ amount: Double, across balances: inout [Double]) {
        guard amount != 0, !balances.isEmpty else { return }
        let total = balances.reduce(0, +)
        if total > 0 {
            for i in balances.indices {
                balances[i] += amount * (balances[i] / total)
            }
        } else {
            balances[0] += amount
        }
    }

    // MARK: - Account Distribution Analysis
    func analyzeAccountDistribution(accounts: [Account]) -> AccountDistributionAnalysis {
        let totalBalance = accounts.totalBalance

        var distribution: [String: Double] = [:]
        for account in accounts {
            distribution[account.type.displayName, default: 0] += account.currentBalance
        }

        let percentageDistribution = distribution.mapValues { balance in
            totalBalance > 0 ? (balance / totalBalance) * 100 : 0
        }

        return AccountDistributionAnalysis(
            totalBalance: totalBalance,
            distribution: distribution,
            percentageDistribution: percentageDistribution
        )
    }

    // MARK: - Helper Methods
    /// Life events whose date falls `month` months from today.
    private func lifeEvents(_ events: [LifeEvent], inMonth month: Int) -> [LifeEvent] {
        events.filter { event in
            let monthsFromNow = Calendar.current.dateComponents([.month], from: Date(), to: event.eventDate).month ?? -1
            return monthsFromNow == month
        }
    }
}

// MARK: - Supporting Structures
struct AccountDistributionAnalysis {
    let totalBalance: Double
    let distribution: [String: Double] // account type -> total balance
    let percentageDistribution: [String: Double] // account type -> percentage
}
