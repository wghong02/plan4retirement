import Foundation

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
    ) -> (projectionDataPoints: [ProjectionDataPoint], projectedBalance: Double) {

        var dataPoints: [ProjectionDataPoint] = []
        var totalBalance = accounts.totalBalance
        let baseAnnualContribution = accounts.reduce(0) { $0 + $1.annualContribution }

        // Convert annual rates into their monthly-compounding equivalents.
        let monthlyGrowthRate = pow(1 + parameters.assetGrowthRate / 100.0, 1.0 / 12.0) - 1
        let inflationRate = parameters.inflationRate / 100.0
        let contributionIncreaseRate = parameters.annualContributionIncreaseRate / 100.0

        let lifeHorizon = max(0, parameters.lifeExpectancy - parameters.currentAge) * 12
        let totalMonths = max(lifeHorizon, horizonMonths ?? 0)

        // Month 0 is the starting point: exactly the current balance, with no growth
        // or contribution applied yet.
        dataPoints.append(ProjectionDataPoint(
            monthIndex: 0,
            age: parameters.currentAge,
            balance: totalBalance,
            contribution: 0,
            growth: 0
        ))

        if totalMonths >= 1 {
            for month in 1...totalMonths {
                let year = month / 12
                let age = parameters.currentAge + year
                let balanceBeforeGrowth = totalBalance

                // Investment growth
                totalBalance *= (1 + monthlyGrowthRate)
                let growth = balanceBeforeGrowth * monthlyGrowthRate

                // Cash flow: contribute (with annual raises) while working, draw down
                // inflation-adjusted spending once retired.
                var contribution = 0.0
                if age < parameters.retirementAge {
                    let annualContribution = baseAnnualContribution * pow(1 + contributionIncreaseRate, Double(year))
                    contribution = annualContribution / 12.0
                    totalBalance += contribution
                } else {
                    let annualSpending = parameters.annualSpendingInRetirement * pow(1 + inflationRate, Double(year))
                    totalBalance -= annualSpending / 12.0
                }

                // One-off life events scheduled for this month
                for event in lifeEvents(parameters.lifeEvents, inMonth: month) {
                    switch event.type {
                    case .housePurchase, .carPurchase, .majorExpense, .medicalExpense:
                        totalBalance -= event.amount
                    case .inheritance:
                        totalBalance += event.amount
                    case .other:
                        break
                    }
                }

                totalBalance = max(0, totalBalance)

                dataPoints.append(ProjectionDataPoint(
                    monthIndex: month,
                    age: age,
                    balance: totalBalance,
                    contribution: contribution,
                    growth: growth
                ))
            }
        }

        let projectedBalance = dataPoints.first { $0.age >= parameters.retirementAge }?.balance
            ?? dataPoints.last?.balance ?? totalBalance

        return (dataPoints, projectedBalance)
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
