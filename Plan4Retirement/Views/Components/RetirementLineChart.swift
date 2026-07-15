import SwiftUI

struct RetirementLineChart: View {
    let dataPoints: [ProjectionDataPoint]
    let title: String
    let height: CGFloat = 350

    private let maxPoints = 60

    @State private var selectedIndex: Int? = nil

    var filteredData: [ProjectionDataPoint] {
        guard dataPoints.count > maxPoints else { return dataPoints }

        // Take every nth point to fit within maxPoints
        let step = max(1, dataPoints.count / maxPoints)
        return stride(from: 0, to: dataPoints.count, by: step).map { dataPoints[$0] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            if filteredData.isEmpty {
                emptyStateView()
            } else {
                // Chart
                ZStack {
                    canvas
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let frame = CGRect(x: 0, y: 0, width: 300, height: height)
                                    updateSelectedIndex(at: value.location, in: frame)
                                }
                        )

                    // Tooltip on touch
                    if let index = selectedIndex, index < filteredData.count {
                        tooltipView(for: filteredData[index])
                    }
                }
                .frame(height: height)
                .background(Color(.systemGray6))
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

                    let text = Text("Age \(point.age)")
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
        VStack(alignment: .leading, spacing: 4) {
            Text("Age \(point.age)")
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
                Text("Year \(point.year):")
                    .font(.caption)
                Spacer()
                Text(point.contribution.formatted(as: true))
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

            VStack(alignment: .center, spacing: 4) {
                Text("Data Points")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(filteredData.count)")
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
    private func updateSelectedIndex(at location: CGPoint, in frame: CGRect) {
        let padding: CGFloat = 50
        let chartWidth = frame.width - (padding * 2)
        let normalizedX = (location.x - padding) / chartWidth
        let index = Int(normalizedX * CGFloat(filteredData.count - 1))

        if index >= 0 && index < filteredData.count {
            selectedIndex = index
        }
    }
}

#Preview {
    let sampleData = generateSampleProjectionData()
    RetirementLineChart(
        dataPoints: sampleData,
        title: "Retirement Projection"
    )
    .padding()
}

private func generateSampleProjectionData() -> [ProjectionDataPoint] {
    var data: [ProjectionDataPoint] = []
    for i in 0..<40 {
        let balance = Double(50000) * (1.0 + Double(i) * 0.08)
        let growth = Double(50000) * Double(i) * 0.08
        data.append(ProjectionDataPoint(
            year: i,
            age: 30 + i,
            balance: balance,
            contribution: 10000.0,
            growth: growth
        ))
    }
    return data
}
