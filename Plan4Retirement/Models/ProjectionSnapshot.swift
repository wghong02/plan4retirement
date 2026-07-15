import Foundation

struct ProjectionSnapshot: Identifiable, Codable {
    let id: String
    var name: String
    var projectedRetirementAge: Int
    var projectedBalance: Double
    var projectionData: [ProjectionDataPoint] // Line chart data
    var parametersUsed: ProjectionParameters // Parameters used for this projection
    let createdDate: Date

    enum CodingKeys: String, CodingKey {
        case id, name, projectedRetirementAge, projectedBalance, projectionData, parametersUsed, createdDate
    }

    init(
        name: String,
        projectedRetirementAge: Int,
        projectedBalance: Double,
        projectionData: [ProjectionDataPoint],
        parametersUsed: ProjectionParameters
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.projectedRetirementAge = projectedRetirementAge
        self.projectedBalance = projectedBalance
        self.projectionData = projectionData
        self.parametersUsed = parametersUsed
        self.createdDate = Date()
    }
}

struct ProjectionDataPoint: Codable {
    let year: Int
    let age: Int
    let balance: Double
    let contribution: Double
    let growth: Double
}

struct ProjectionParameters: Codable {
    var currentAge: Int
    var retirementAge: Int
    var inflationRate: Double // e.g., 2.5
    var assetGrowthRate: Double // e.g., 7.0
    var lifeExpectancy: Int
    var annualSpendingInRetirement: Double
    var lifeEvents: [LifeEvent]

    init(
        currentAge: Int = 30,
        retirementAge: Int = 67,
        inflationRate: Double = 2.5,
        assetGrowthRate: Double = 7.0,
        lifeExpectancy: Int = 95,
        annualSpendingInRetirement: Double = 50000,
        lifeEvents: [LifeEvent] = []
    ) {
        self.currentAge = currentAge
        self.retirementAge = retirementAge
        self.inflationRate = inflationRate
        self.assetGrowthRate = assetGrowthRate
        self.lifeExpectancy = lifeExpectancy
        self.annualSpendingInRetirement = annualSpendingInRetirement
        self.lifeEvents = lifeEvents
    }
}
