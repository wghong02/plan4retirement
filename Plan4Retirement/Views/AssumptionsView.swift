import SwiftUI

struct AssumptionsView: View {
    @EnvironmentObject var settings: SettingsService
    @State private var lifeEvents: [LifeEvent] = []
    @State private var showAddLifeEvent = false

    private let lifeEventService = LifeEventService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    Stepper("Current Age: \(settings.currentAge)", value: $settings.currentAge, in: 18...80)

                    Stepper("Retirement Age: \(settings.retirementAge)", value: $settings.retirementAge, in: settings.currentAge...120)

                    Stepper("Life Expectancy: \(settings.lifeExpectancy)", value: $settings.lifeExpectancy, in: settings.retirementAge...120)
                }

                Section("Economic Assumptions") {
                    HStack {
                        Text("Annual Inflation Rate")
                        Spacer()
                        TextField("Inflation", value: $settings.inflationRate, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                        Text("%")
                    }

                    HStack {
                        Text("Asset Growth Rate")
                        Spacer()
                        TextField("Growth", value: $settings.assetGrowthRate, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                        Text("%")
                    }

                    HStack {
                        Text("Annual Spending in Retirement")
                        Spacer()
                        TextField("Spending", value: $settings.annualSpendingInRetirement, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .frame(width: 120)
                    }
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
            .navigationTitle("Assumptions & Parameters")
            .onAppear(perform: loadLifeEvents)
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
