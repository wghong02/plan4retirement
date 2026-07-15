import Foundation
import Combine

class SettingsService: ObservableObject {
    @Published var currentAge: Int {
        didSet { UserDefaults.standard.set(currentAge, forKey: "currentAge") }
    }

    @Published var retirementAge: Int {
        didSet { UserDefaults.standard.set(retirementAge, forKey: "retirementAge") }
    }

    @Published var inflationRate: Double {
        didSet { UserDefaults.standard.set(inflationRate, forKey: "inflationRate") }
    }

    @Published var assetGrowthRate: Double {
        didSet { UserDefaults.standard.set(assetGrowthRate, forKey: "assetGrowthRate") }
    }

    @Published var lifeExpectancy: Int {
        didSet { UserDefaults.standard.set(lifeExpectancy, forKey: "lifeExpectancy") }
    }

    @Published var annualSpendingInRetirement: Double {
        didSet { UserDefaults.standard.set(annualSpendingInRetirement, forKey: "annualSpendingInRetirement") }
    }

    @Published var maxProjectionSnapshots: Int {
        didSet { UserDefaults.standard.set(maxProjectionSnapshots, forKey: "maxProjectionSnapshots") }
    }

    static let shared = SettingsService()

    init() {
        let defaults = UserDefaults.standard

        self.currentAge = defaults.integer(forKey: "currentAge") == 0 ? 30 : defaults.integer(forKey: "currentAge")
        self.retirementAge = defaults.integer(forKey: "retirementAge") == 0 ? 67 : defaults.integer(forKey: "retirementAge")
        self.inflationRate = defaults.object(forKey: "inflationRate") as? Double ?? 2.5
        self.assetGrowthRate = defaults.object(forKey: "assetGrowthRate") as? Double ?? 7.0
        self.lifeExpectancy = defaults.integer(forKey: "lifeExpectancy") == 0 ? 95 : defaults.integer(forKey: "lifeExpectancy")
        self.annualSpendingInRetirement = defaults.object(forKey: "annualSpendingInRetirement") as? Double ?? 50000
        self.maxProjectionSnapshots = defaults.integer(forKey: "maxProjectionSnapshots") == 0 ? 10 : defaults.integer(forKey: "maxProjectionSnapshots")
    }

    func getProjectionParameters(lifeEvents: [LifeEvent] = []) -> ProjectionParameters {
        return ProjectionParameters(
            currentAge: currentAge,
            retirementAge: retirementAge,
            inflationRate: inflationRate,
            assetGrowthRate: assetGrowthRate,
            lifeExpectancy: lifeExpectancy,
            annualSpendingInRetirement: annualSpendingInRetirement,
            lifeEvents: lifeEvents
        )
    }

    func resetToDefaults() {
        currentAge = 30
        retirementAge = 67
        inflationRate = 2.5
        assetGrowthRate = 7.0
        lifeExpectancy = 95
        annualSpendingInRetirement = 50000
        maxProjectionSnapshots = 10
    }
}
