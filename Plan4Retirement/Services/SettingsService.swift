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

    @Published var lifeExpectancy: Int {
        didSet { UserDefaults.standard.set(lifeExpectancy, forKey: "lifeExpectancy") }
    }

    @Published var annualSpendingInRetirement: Double {
        didSet { UserDefaults.standard.set(annualSpendingInRetirement, forKey: "annualSpendingInRetirement") }
    }

    @Published var maxProjectionSnapshots: Int {
        didSet { UserDefaults.standard.set(maxProjectionSnapshots, forKey: "maxProjectionSnapshots") }
    }

    @Published var maxMonthsDisplayed: Int {
        didSet { UserDefaults.standard.set(maxMonthsDisplayed, forKey: "maxMonthsDisplayed") }
    }

    @Published var maxYearsDisplayed: Int {
        didSet { UserDefaults.standard.set(maxYearsDisplayed, forKey: "maxYearsDisplayed") }
    }

    /// When true, projected amounts are shown in today's dollars (deflated by inflation).
    @Published var showInflationAdjusted: Bool {
        didSet { UserDefaults.standard.set(showInflationAdjusted, forKey: "showInflationAdjusted") }
    }

    static let shared = SettingsService()

    init() {
        let defaults = UserDefaults.standard

        self.currentAge = defaults.integer(forKey: "currentAge") == 0 ? 30 : defaults.integer(forKey: "currentAge")
        self.retirementAge = defaults.integer(forKey: "retirementAge") == 0 ? 67 : defaults.integer(forKey: "retirementAge")
        self.inflationRate = defaults.object(forKey: "inflationRate") as? Double ?? 2.5
        self.lifeExpectancy = defaults.integer(forKey: "lifeExpectancy") == 0 ? 95 : defaults.integer(forKey: "lifeExpectancy")
        self.annualSpendingInRetirement = defaults.object(forKey: "annualSpendingInRetirement") as? Double ?? 50000
        self.maxProjectionSnapshots = defaults.integer(forKey: "maxProjectionSnapshots") == 0 ? 10 : defaults.integer(forKey: "maxProjectionSnapshots")
        self.maxMonthsDisplayed = defaults.integer(forKey: "maxMonthsDisplayed") == 0 ? 60 : defaults.integer(forKey: "maxMonthsDisplayed")
        self.maxYearsDisplayed = defaults.integer(forKey: "maxYearsDisplayed") == 0 ? 100 : defaults.integer(forKey: "maxYearsDisplayed")
        self.showInflationAdjusted = defaults.bool(forKey: "showInflationAdjusted")
    }

    func getProjectionParameters(lifeEvents: [LifeEvent] = []) -> ProjectionParameters {
        return ProjectionParameters(
            currentAge: currentAge,
            retirementAge: retirementAge,
            inflationRate: inflationRate,
            lifeExpectancy: lifeExpectancy,
            annualSpendingInRetirement: annualSpendingInRetirement,
            lifeEvents: lifeEvents
        )
    }

    func resetToDefaults() {
        currentAge = 30
        retirementAge = 67
        inflationRate = 2.5
        lifeExpectancy = 95
        annualSpendingInRetirement = 50000
        maxProjectionSnapshots = 10
        maxMonthsDisplayed = 60
        maxYearsDisplayed = 100
        showInflationAdjusted = false
    }
}
