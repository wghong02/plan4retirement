import Foundation

class ProjectionCalculator {

    // MARK: - Main Projection Calculation
    func calculateRetirementProjection(
        accounts: [Account],
        currentAge: Int,
        retirementAge: Int,
        inflationRate: Double,
        assetGrowthRate: Double,
        lifeExpectancy: Int,
        lifeEvents: [LifeEvent] = []
    ) -> (projectionDataPoints: [ProjectionDataPoint], projectedBalance: Double, projectedRetirementAge: Int?) {

        var dataPoints: [ProjectionDataPoint] = []
        var totalBalance = accounts.reduce(0) { $0 + $1.currentBalance }
        let totalAnnualContribution = accounts.reduce(0) { $0 + $1.annualContribution }
        let averageROI = calculateWeightedAverageROI(accounts: accounts)

        let yearlyGrowthRate = (assetGrowthRate / 100.0) + (inflationRate / 100.0)
        var projectedRetirementAge: Int? = nil

        for year in 0...(lifeExpectancy - currentAge) {
            let age = currentAge + year
            let balanceBeforeGrowth = totalBalance

            // Apply growth
            totalBalance = totalBalance * (1 + assetGrowthRate / 100.0)

            // Add contributions (only if not retired)
            if age < retirementAge {
                totalBalance += totalAnnualContribution
            }

            // Apply life events
            let eventsThisYear = lifeEvents.filter { event in
                let eventYear = Calendar.current.dateComponents([.year], from: event.eventDate, to: Date()).year ?? 0
                return eventYear == year
            }

            for event in eventsThisYear {
                if event.type == .housePurchase || event.type == .carPurchase || event.type == .majorExpense || event.type == .medicalExpense {
                    totalBalance -= event.amount
                } else if event.type == .inheritance {
                    totalBalance += event.amount
                }
            }

            let growth = totalBalance - balanceBeforeGrowth
            let contribution = age < retirementAge ? totalAnnualContribution : 0

            let dataPoint = ProjectionDataPoint(
                year: year,
                age: age,
                balance: max(0, totalBalance),
                contribution: contribution,
                growth: growth
            )

            dataPoints.append(dataPoint)

            // Check if we've reached retirement age and have enough
            if age == retirementAge && projectedRetirementAge == nil {
                projectedRetirementAge = age
            }
        }

        return (dataPoints, max(0, totalBalance), projectedRetirementAge)
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

        let baselineResult = calculateRetirementProjection(
            accounts: accounts,
            currentAge: parameters.currentAge,
            retirementAge: parameters.retirementAge,
            inflationRate: parameters.inflationRate,
            assetGrowthRate: parameters.assetGrowthRate,
            lifeExpectancy: parameters.lifeExpectancy,
            lifeEvents: parameters.lifeEvents
        )

        let conservativeResult = calculateRetirementProjection(
            accounts: accounts,
            currentAge: conservative.currentAge,
            retirementAge: conservative.retirementAge,
            inflationRate: conservative.inflationRate,
            assetGrowthRate: conservative.assetGrowthRate,
            lifeExpectancy: conservative.lifeExpectancy,
            lifeEvents: conservative.lifeEvents
        )

        let aggressiveResult = calculateRetirementProjection(
            accounts: accounts,
            currentAge: aggressive.currentAge,
            retirementAge: aggressive.retirementAge,
            inflationRate: aggressive.inflationRate,
            assetGrowthRate: aggressive.assetGrowthRate,
            lifeExpectancy: aggressive.lifeExpectancy,
            lifeEvents: aggressive.lifeEvents
        )

        return [
            ScenarioResult(
                name: "Conservative",
                retirementAge: conservativeResult.projectedRetirementAge ?? parameters.retirementAge,
                projectedBalance: conservativeResult.projectedBalance,
                dataPoints: conservativeResult.projectionDataPoints,
                assumptions: conservative
            ),
            ScenarioResult(
                name: "Baseline",
                retirementAge: baselineResult.projectedRetirementAge ?? parameters.retirementAge,
                projectedBalance: baselineResult.projectedBalance,
                dataPoints: baselineResult.projectionDataPoints,
                assumptions: parameters
            ),
            ScenarioResult(
                name: "Aggressive",
                retirementAge: aggressiveResult.projectedRetirementAge ?? parameters.retirementAge,
                projectedBalance: aggressiveResult.projectedBalance,
                dataPoints: aggressiveResult.projectionDataPoints,
                assumptions: aggressive
            )
        ]
    }

    // MARK: - Life Event Impact Analysis
    func calculateLifeEventImpact(
        accounts: [Account],
        parameters: ProjectionParameters,
        lifeEvent: LifeEvent
    ) -> (impactAmount: Double, balanceWithoutEvent: Double, balanceWithEvent: Double) {

        let withoutEvent = calculateRetirementProjection(
            accounts: accounts,
            currentAge: parameters.currentAge,
            retirementAge: parameters.retirementAge,
            inflationRate: parameters.inflationRate,
            assetGrowthRate: parameters.assetGrowthRate,
            lifeExpectancy: parameters.lifeExpectancy,
            lifeEvents: []
        )

        let withEvent = calculateRetirementProjection(
            accounts: accounts,
            currentAge: parameters.currentAge,
            retirementAge: parameters.retirementAge,
            inflationRate: parameters.inflationRate,
            assetGrowthRate: parameters.assetGrowthRate,
            lifeExpectancy: parameters.lifeExpectancy,
            lifeEvents: [lifeEvent]
        )

        let impact = withoutEvent.projectedBalance - withEvent.projectedBalance

        return (impactAmount: impact, balanceWithoutEvent: withoutEvent.projectedBalance, balanceWithEvent: withEvent.projectedBalance)
    }

    // MARK: - Account Distribution Analysis
    func analyzeAccountDistribution(accounts: [Account]) -> AccountDistributionAnalysis {
        let totalBalance = accounts.reduce(0) { $0 + $1.currentBalance }

        var distribution: [String: Double] = [:]
        var percentageDistribution: [String: Double] = [:]

        for account in accounts {
            let key = account.type.displayName
            distribution[key, default: 0] += account.currentBalance
            percentageDistribution[key, default: 0] += (account.currentBalance / totalBalance) * 100
        }

        return AccountDistributionAnalysis(
            totalBalance: totalBalance,
            distribution: distribution,
            percentageDistribution: percentageDistribution
        )
    }

    // MARK: - Helper Methods
    private func calculateWeightedAverageROI(accounts: [Account]) -> Double {
        let totalBalance = accounts.reduce(0) { $0 + $1.currentBalance }

        guard totalBalance > 0 else { return 5.0 }

        let weightedROI = accounts.reduce(0) { sum, account in
            sum + (account.expectedROI * (account.currentBalance / totalBalance))
        }

        return weightedROI
    }

    func estimateRetirementDate(
        accounts: [Account],
        targetAmount: Double,
        currentAge: Int,
        annualContribution: Double,
        expectedROI: Double
    ) -> Int? {
        var balance = accounts.reduce(0) { $0 + $1.currentBalance }
        let growthRate = expectedROI / 100.0

        for year in 0...100 {
            if balance >= targetAmount {
                return currentAge + year
            }
            balance = balance * (1 + growthRate) + annualContribution
        }

        return nil
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
