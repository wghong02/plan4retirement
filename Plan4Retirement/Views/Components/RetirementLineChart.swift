import SwiftUI

struct RetirementLineChart: View {
    let dataPoints: [ProjectionDataPoint]
    let title: String
    /// Calendar year/month corresponding to projection month 0. Defaults to today;
    /// saved snapshots pass the date they were created so their axis stays fixed.
    var startYear: Int = Calendar.current.component(.year, from: Date())
    var startMonth: Int = Calendar.current.component(.month, from: Date())
    /// How many months / years to show in each display mode.
    var maxMonths: Int = 60
    var maxYears: Int = 100
    let height: CGFloat = 350

    @State private var selectedIndex: Int? = nil
    @Binding var displayMode: DisplayMode

    enum DisplayMode {
        case monthly // First 5 years at monthly resolution
        case yearly  // Whole horizon, one point per year
    }

    private static let monthAbbreviations = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]

    var filteredData: [ProjectionDataPoint] {
        switch displayMode {
        case .monthly:
            // Near-term detail: first `maxMonths` months as-is.
            return Array(dataPoints.prefix(maxMonths))
        case .yearly:
            // One point per year, capped at `maxYears`.
            let yearly = dataPoints.filter { $0.monthIndex % 12 == 0 }
            return Array(yearly.prefix(maxYears))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and mode selector
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                Picker("Mode", selection: $displayMode) {
                    Text("Monthly").tag(DisplayMode.monthly)
                    Text("Yearly").tag(DisplayMode.yearly)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            if filteredData.isEmpty {
                emptyStateView()
            } else {
                // Chart. Detail requires a press-and-hold so a plain drag still scrolls.
                GeometryReader { geo in
                    ZStack {
                        canvas
                            .gesture(
                                LongPressGesture(minimumDuration: 0.2)
                                    .sequenced(before: DragGesture(minimumDistance: 0))
                                    .onChanged { value in
                                        if case .second(true, let drag?) = value {
                                            updateSelectedIndex(at: drag.location, in: geo.size)
                                        }
                                    }
                                    .onEnded { _ in selectedIndex = nil }
                            )

                        // Tooltip while holding
                        if let index = selectedIndex, index < filteredData.count {
                            tooltipView(for: filteredData[index])
                        }
                    }
                }
                .frame(height: height)
                // Darker shade signals this area is interactive (press-and-hold), not scrollable.
                .background(Color(.systemGray4))
                .cornerRadius(8)

                // Stats
                statsView()
            }
        }
    }

    // MARK: - Canvas View
    private var canvas: some View {
        Canvas { context, size in
            let maxBalance = filteredData.map(\.balance).max() ?? 100000
            let minBalance = filteredData.map(\.balance).min() ?? 0
            let balanceRange = maxBalance - minBalance
            let padding: CGFloat = 50
            let chartWidth = size.width - (padding * 2)
            let chartHeight = size.height - (padding * 1.5)

            // Draw Y axis
            var yPath = Path()
            yPath.move(to: CGPoint(x: padding, y: padding))
            yPath.addLine(to: CGPoint(x: padding, y: size.height - padding / 2))
            context.stroke(yPath, with: .color(.gray), lineWidth: 1)

            // Draw X axis
            var xPath = Path()
            xPath.move(to: CGPoint(x: padding, y: size.height - padding / 2))
            xPath.addLine(to: CGPoint(x: size.width - padding, y: size.height - padding / 2))
            context.stroke(xPath, with: .color(.gray), lineWidth: 1)

            // Draw grid and Y axis labels
            for i in stride(from: 0, through: 4, by: 1) {
                let y = padding + CGFloat(i) * (chartHeight / 4)
                let balance = maxBalance - (Double(i) / 4.0) * balanceRange

                // Grid line
                var gridPath = Path()
                gridPath.move(to: CGPoint(x: padding, y: y))
                gridPath.addLine(to: CGPoint(x: size.width - padding, y: y))
                context.stroke(gridPath, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)

                // Y axis label
                let text = Text(balance.formattedAsAxisLabel())
                    .font(.caption2)
                    .foregroundColor(.gray)
                context.draw(text, at: CGPoint(x: padding - 40, y: y), anchor: .center)
            }

            // Draw data line
            var dataPath = Path()
            for (index, point) in filteredData.enumerated() {
                let x = padding + (CGFloat(index) / CGFloat(max(1, filteredData.count - 1))) * chartWidth
                let normalizedBalance = (point.balance - minBalance) / max(1, balanceRange)
                let y = size.height - padding / 2 - normalizedBalance * chartHeight

                if index == 0 {
                    dataPath.move(to: CGPoint(x: x, y: y))
                } else {
                    dataPath.addLine(to: CGPoint(x: x, y: y))
                }
            }

            context.stroke(dataPath, with: .color(.blue), lineWidth: 2)

            // Draw data points
            for (index, point) in filteredData.enumerated() {
                let x = padding + (CGFloat(index) / CGFloat(max(1, filteredData.count - 1))) * chartWidth
                let normalizedBalance = (point.balance - minBalance) / max(1, balanceRange)
                let y = size.height - padding / 2 - normalizedBalance * chartHeight

                let circle = Path(
                    ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                )

                let fillColor: Color = (selectedIndex == index) ? .blue : .blue.opacity(0.6)
                context.fill(circle, with: .color(fillColor))
            }

            // Draw X axis labels
            let labelInterval = max(1, filteredData.count / 6)
            for (index, point) in filteredData.enumerated() {
                if index % labelInterval == 0 || index == filteredData.count - 1 {
                    let x = padding + (CGFloat(index) / CGFloat(max(1, filteredData.count - 1))) * chartWidth

                    let text = Text(verbatim: xAxisLabel(for: point))
                        .font(.caption2)
                        .foregroundColor(.gray)
                    context.draw(text, at: CGPoint(x: x, y: size.height - 20), anchor: .center)
                }
            }
        }
    }

    // MARK: - Tooltip View
    @ViewBuilder
    private func tooltipView(for point: ProjectionDataPoint) -> some View {
        // Stored figures are per-month; scale to per-year in yearly mode.
        let isYearly = displayMode == .yearly
        let periodMultiplier: Double = isYearly ? 12 : 1
        let contributionLabel = isYearly ? "Annual Contribution:" : "Monthly Contribution:"
        let growthLabel = isYearly ? "Annual Growth:" : "Monthly Growth:"

        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: periodLabel(for: point))
                .font(.subheadline)
                .fontWeight(.semibold)

            Divider()

            HStack {
                Text("Balance:")
                    .font(.caption)
                Spacer()
                Text(point.balance.formatted(as: true))
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            HStack {
                Text("Age:")
                    .font(.caption)
                Spacer()
                Text(verbatim: "\(point.age)")
                    .font(.caption)
            }

            HStack {
                Text(contributionLabel)
                    .font(.caption)
                Spacer()
                Text((point.contribution * periodMultiplier).formatted(as: true))
                    .font(.caption)
            }

            HStack {
                Text(growthLabel)
                    .font(.caption)
                Spacer()
                Text((point.growth * periodMultiplier).formatted(as: true))
                    .font(.caption)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
        .padding()
    }

    // MARK: - Stats View
    @ViewBuilder
    private func statsView() -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Starting")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text((filteredData.first?.balance ?? 0).formatted(as: true))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Ending")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text((filteredData.last?.balance ?? 0).formatted(as: true))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: "chart.line")
                .font(.system(size: 32))
                .foregroundColor(.gray)
            Text("No data available")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Helpers
    private func updateSelectedIndex(at location: CGPoint, in size: CGSize) {
        let padding: CGFloat = 50
        let chartWidth = size.width - (padding * 2)
        guard chartWidth > 0 else { return }
        let normalizedX = (location.x - padding) / chartWidth
        let index = Int((normalizedX * CGFloat(filteredData.count - 1)).rounded())

        if index >= 0 && index < filteredData.count {
            selectedIndex = index
        }
    }

    /// Compact axis label: calendar year in yearly mode, "MMM YY" in monthly mode.
    private func xAxisLabel(for point: ProjectionDataPoint) -> String {
        switch displayMode {
        case .yearly:
            return "\(startYear + point.year)"
        case .monthly:
            let (year, month) = calendarComponents(for: point)
            return "\(Self.monthAbbreviations[month]) \(year % 100)"
        }
    }

    /// Full label used in the tooltip header.
    private func periodLabel(for point: ProjectionDataPoint) -> String {
        switch displayMode {
        case .yearly:
            return "\(startYear + point.year)"
        case .monthly:
            let (year, month) = calendarComponents(for: point)
            return "\(Self.monthAbbreviations[month]) \(year)"
        }
    }

    /// Absolute (year, 0-based month) for a data point given the start anchor.
    private func calendarComponents(for point: ProjectionDataPoint) -> (year: Int, month: Int) {
        let absoluteMonth = (startMonth - 1) + point.monthIndex
        return (startYear + absoluteMonth / 12, absoluteMonth % 12)
    }
}

#Preview {
    let sampleData = generateSampleProjectionData()
    RetirementLineChart(
        dataPoints: sampleData,
        title: "Retirement Projection",
        displayMode: .constant(.yearly)
    )
    .padding()
}

private func generateSampleProjectionData() -> [ProjectionDataPoint] {
    var data: [ProjectionDataPoint] = []
    for month in 0..<480 {
        let year = month / 12
        let balance = Double(50000) * (1.0 + Double(year) * 0.08)
        let growth = Double(50000) * Double(year) * 0.08
        data.append(ProjectionDataPoint(
            monthIndex: month,
            age: 30 + year,
            balance: balance,
            contribution: 10000.0 / 12.0,
            growth: growth
        ))
    }
    return data
}
