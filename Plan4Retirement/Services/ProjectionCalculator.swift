import Foundation

class ProjectionCalculator {

    // MARK: - Main Projection Calculation
    func calculateRetirementProjection(
        accounts: [Account],
        parameters: ProjectionParameters
    ) -> (projectionDataPoints: [ProjectionDataPoint], projectedBalance: Double) {

        var dataPoints: [ProjectionDataPoint] = []
        var totalBalance = accounts.totalBalance
        let baseContribution = accounts.reduce(0) { $0 + $1.annualContribution }

        let growthRate = parameters.assetGrowthRate / 100.0
        let inflationRate = parameters.inflationRate / 100.0

        for year in 0...(parameters.lifeExpectancy - parameters.currentAge) {
            let age = parameters.currentAge + year
            let balanceBeforeGrowth = totalBalance

            // Investment growth
            totalBalance *= (1 + growthRate)
            let growth = balanceBeforeGrowth * growthRate

            // Inflation-adjusted cash flow: contribute while working, draw down once retired.
            let inflationFactor = pow(1 + inflationRate, Double(year))
            var contribution = 0.0
            if age < parameters.retirementAge {
                contribution = baseContribution * inflationFactor
                totalBalance += contribution
            } else {
                totalBalance -= parameters.annualSpendingInRetirement * inflationFactor
            }

            // One-off life events scheduled for this year
            for event in lifeEvents(parameters.lifeEvents, inYear: year) {
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
                year: year,
                age: age,
                balance: totalBalance,
                contribution: contribution,
                growth: growth
            ))
        }

        let projectedBalance = dataPoints.first { $0.age >= parameters.retirementAge }?.balance
            ?? dataPoints.last?.balance ?? totalBalance

        return (dataPoints, projectedBalance)
    }

    // MARK: - Scenario Comparison
    func generateScenarios(
        accounts: [Account],
        parameters: ProjectionParameters
    ) -> [ScenarioResult] {

        let conservative = ProjectionParameters(
            currentAge: parameters.currentAge,
            retirementAge: parameters.retirementAge,
            inflationRate: parameters.inflationRate + 0.5,
            assetGrowthRate: max(1, parameters.assetGrowthRate - 2),
            lifeExpectancy: parameters.lifeExpectancy,
            annualSpendingInRetirement: parameters.annualSpendingInRetirement,
            lifeEvents: parameters.lifeEvents
        )

        let aggressive = ProjectionParameters(
            currentAge: parameters.currentAge,
            retirementAge: max(50, parameters.retirementAge - 3),
            inflationRate: max(0, parameters.inflationRate - 0.5),
            assetGrowthRate: parameters.assetGrowthRate + 2,
            lifeExpectancy: parameters.lifeExpectancy,
            annualSpendingInRetirement: parameters.annualSpendingInRetirement,
            lifeEvents: parameters.lifeEvents
        )

        func scenario(_ name: String, _ params: ProjectionParameters) -> ScenarioResult {
            let result = calculateRetirementProjection(accounts: accounts, parameters: params)
            return ScenarioResult(
                name: name,
                retirementAge: params.retirementAge,
                projectedBalance: result.projectedBalance,
                dataPoints: result.projectionDataPoints,
                assumptions: params
            )
        }

        return [
            scenario("Conservative", conservative),
            scenario("Baseline", parameters),
            scenario("Aggressive", aggressive)
        ]
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
    /// Life events whose date falls `year` years from today.
    private func lifeEvents(_ events: [LifeEvent], inYear year: Int) -> [LifeEvent] {
        events.filter { event in
            let yearsFromNow = Calendar.current.dateComponents([.year], from: Date(), to: event.eventDate).year ?? -1
            return yearsFromNow == year
        }
    }
}

// MARK: - Supporting Structures
struct ScenarioResult: Codable {
    let name: String
    let retirementAge: Int
    let projectedBalance: Double
    let dataPoints: [ProjectionDataPoint]
    let assumptions: ProjectionParameters
}

struct AccountDistributionAnalysis {
    let totalBalance: Double
    let distribution: [String: Double] // account type -> total balance
    let percentageDistribution: [String: Double] // account type -> percentage
}
