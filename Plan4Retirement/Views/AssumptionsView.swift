import SwiftUI

struct AssumptionsView: View {
    @EnvironmentObject var settings: SettingsService
    @State private var lifeEvents: [LifeEvent] = []
    @State private var showAddLifeEvent = false

    // Editing buffers. Valid values are cached to `settings` automatically as
    // they change; invalid intermediate text is simply not committed.
    @State private var currentAgeText = ""
    @State private var retirementAgeText = ""
    @State private var lifeExpectancyText = ""
    @State private var inflationText = ""
    @State private var growthText = ""
    @State private var contributionIncreaseText = ""
    @State private var spendingText = ""

    @FocusState private var inputActive: Bool

    private let lifeEventService = LifeEventService()

    private let rateError = "Please enter a number within the bound (-100% to 10000%)"
    private let maxDecimals = 4

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    StepperField(
                        title: "Current Age",
                        text: $currentAgeText,
                        range: 18...100,
                        focus: $inputActive,
                        isValid: currentAge != nil,
                        errorMessage: "Please enter an age between 18 and 100"
                    )
                    .onChange(of: currentAgeText) { _ in commit() }

                    StepperField(
                        title: "Retirement Age",
                        text: $retirementAgeText,
                        range: 18...120,
                        focus: $inputActive,
                        isValid: retirementAge != nil,
                        errorMessage: "Must be above current age and at most 120"
                    )
                    .onChange(of: retirementAgeText) { _ in commit() }

                    StepperField(
                        title: "Life Expectancy",
                        text: $lifeExpectancyText,
                        range: 18...120,
                        focus: $inputActive,
                        isValid: lifeExpectancy != nil,
                        errorMessage: "Must be at least retirement age and at most 120"
                    )
                    .onChange(of: lifeExpectancyText) { _ in commit() }
                }

                Section("Economic Assumptions") {
                    DecimalField(
                        title: "Annual Inflation Rate",
                        text: $inflationText,
                        suffix: "%",
                        focus: $inputActive,
                        isValid: inflation != nil,
                        errorMessage: rateError
                    )
                    .onChange(of: inflationText) { _ in capDecimals(&inflationText); commit() }

                    DecimalField(
                        title: "Asset Growth Rate",
                        text: $growthText,
                        suffix: "%",
                        focus: $inputActive,
                        isValid: growth != nil,
                        errorMessage: rateError
                    )
                    .onChange(of: growthText) { _ in capDecimals(&growthText); commit() }

                    DecimalField(
                        title: "Annual Contribution Increase",
                        text: $contributionIncreaseText,
                        suffix: "%",
                        focus: $inputActive,
                        isValid: contributionIncrease != nil,
                        errorMessage: rateError
                    )
                    .onChange(of: contributionIncreaseText) { _ in capDecimals(&contributionIncreaseText); commit() }

                    DecimalField(
                        title: "Annual Spending in Retirement",
                        text: $spendingText,
                        suffix: "USD",
                        focus: $inputActive,
                        isValid: spending != nil,
                        errorMessage: "Please enter an amount of 0 or more"
                    )
                    .onChange(of: spendingText) { _ in capDecimals(&spendingText); commit() }
                }

                Section("Life Events") {
                    if lifeEvents.isEmpty {
                        Text("No life events added")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(lifeEvents) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(event.name)
                                            .font(.headline)
                                        Text(event.type.displayName)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    Text(event.amount.formatted(as: true))
                                        .font(.headline)
                                }

                                Text(event.eventDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                if let notes = event.notes {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .onDelete(perform: deleteLifeEvent)
                    }

                    Button(action: { showAddLifeEvent = true }) {
                        Label("Add Life Event", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Assumptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(action: { inputActive = false }) {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .onAppear {
                loadLifeEvents()
                loadFromSettings()
            }
            .sheet(isPresented: $showAddLifeEvent) {
                AddLifeEventView(isPresented: $showAddLifeEvent) { newEvent in
                    do {
                        try lifeEventService.addLifeEvent(newEvent)
                        loadLifeEvents()
                    } catch {
                        print("Error adding life event: \(error)")
                    }
                }
            }
        }
    }

    // MARK: - Validation
    private var currentAge: Int? {
        guard let value = Int(currentAgeText), (18...100).contains(value) else { return nil }
        return value
    }

    private var retirementAge: Int? {
        guard let value = Int(retirementAgeText), let current = currentAge,
              value > current, value <= 120 else { return nil }
        return value
    }

    private var lifeExpectancy: Int? {
        guard let value = Int(lifeExpectancyText), let retirement = retirementAge,
              value >= retirement, value <= 120 else { return nil }
        return value
    }

    private var inflation: Double? { validRate(inflationText) }
    private var growth: Double? { validRate(growthText) }
    private var contributionIncrease: Double? { validRate(contributionIncreaseText) }

    private var spending: Double? {
        guard let value = Double(spendingText), value >= 0 else { return nil }
        return value
    }

    private func validRate(_ text: String) -> Double? {
        guard let value = Double(text), value >= -100, value <= 10000 else { return nil }
        return value
    }

    // MARK: - Load / Auto-save
    private func loadFromSettings() {
        currentAgeText = "\(settings.currentAge)"
        retirementAgeText = "\(settings.retirementAge)"
        lifeExpectancyText = "\(settings.lifeExpectancy)"
        inflationText = formatRate(settings.inflationRate)
        growthText = formatRate(settings.assetGrowthRate)
        contributionIncreaseText = formatRate(settings.annualContributionIncreaseRate)
        spendingText = "\(Int(settings.annualSpendingInRetirement))"
    }

    /// Cache every currently-valid field to settings. Invalid fields are skipped.
    private func commit() {
        if let currentAge { settings.currentAge = currentAge }
        if let retirementAge { settings.retirementAge = retirementAge }
        if let lifeExpectancy { settings.lifeExpectancy = lifeExpectancy }
        if let inflation { settings.inflationRate = inflation }
        if let growth { settings.assetGrowthRate = growth }
        if let contributionIncrease { settings.annualContributionIncreaseRate = contributionIncrease }
        if let spending { settings.annualSpendingInRetirement = spending }
    }

    /// Restrict a decimal string to a single point and at most `maxDecimals` places.
    private func capDecimals(_ text: inout String) {
        guard let dotIndex = text.firstIndex(of: ".") else { return }
        let integerPart = text[..<dotIndex]
        let fraction = text[text.index(after: dotIndex)...]
            .replacingOccurrences(of: ".", with: "")
            .prefix(maxDecimals)
        let capped = integerPart + "." + fraction
        if capped != text {
            text = String(capped)
        }
    }

    /// Whole numbers show without a trailing ".0".
    private func formatRate(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : "\(value)"
    }

    // MARK: - Life Events
    private func loadLifeEvents() {
        do {
            lifeEvents = try lifeEventService.getAllLifeEvents()
        } catch {
            print("Error loading life events: \(error)")
        }
    }

    private func deleteLifeEvent(at offsets: IndexSet) {
        for index in offsets {
            let event = lifeEvents[index]
            do {
                try lifeEventService.deleteLifeEvent(by: event.id)
                loadLifeEvents()
            } catch {
                print("Error deleting life event: \(error)")
            }
        }
    }
}

#Preview {
    AssumptionsView()
        .environmentObject(SettingsService.shared)
}
