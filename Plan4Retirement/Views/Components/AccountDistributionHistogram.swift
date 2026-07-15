import SwiftUI

struct AccountDistributionHistogram: View {
    let distribution: [String: Double]
    let title: String
    let height: CGFloat = 280

    @State private var selectedBar: String? = nil
    @State private var zoomScale: CGFloat = 1.0

    private let colors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink, .yellow, .cyan
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            if distribution.isEmpty {
                emptyStateView()
            } else {
                // Chart
                ZStack {
                    canvas
                        .gesture(
                            TapGesture().onEnded { location in
                                let frame = CGRect(x: 0, y: 0, width: 300, height: height)
                                updateSelectedBar(at: location, in: frame)
                            }
                        )

                    // Tooltip on bar selection
                    if let barName = selectedBar, let value = distribution[barName] {
                        tooltipView(for: barName, value: value)
                    }
                }
                .frame(height: height)
                .background(Color(.systemGray6))
                .cornerRadius(8)

                // Legend with values
                legendView()
            }
        }
    }

    // MARK: - Canvas View
    private var canvas: some View {
        Canvas { context, size in
            let maxValue = distribution.values.max() ?? 1
            let padding: CGFloat = 40
            let chartWidth = size.width - (padding * 2)
            let chartHeight = size.height - (padding * 1.5)
            let barCount = distribution.count
            let barWidth = chartWidth / CGFloat(barCount)

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

            // Draw Y axis grid lines and labels
            for i in stride(from: 0, through: 4, by: 1) {
                let y = padding + CGFloat(i) * (chartHeight / 4)
                let value = maxValue - (Double(i) / 4.0) * maxValue
                let labelValue = formatYAxisLabel(value)

                // Grid line
                var gridPath = Path()
                gridPath.move(to: CGPoint(x: padding, y: y))
                gridPath.addLine(to: CGPoint(x: size.width - padding, y: y))
                context.stroke(gridPath, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)

                // Y axis label
                var text = Text(labelValue)
                    .font(.caption2)
                    .foregroundColor(.gray)
                context.draw(text, at: CGPoint(x: padding - 40, y: y), anchor: .center)
            }

            // Draw bars
            for (index, (key, value)) in distribution.sorted(by: { $0.key < $1.key }).enumerated() {
                let barHeight = (value / maxValue) * chartHeight
                let x = padding + CGFloat(index) * barWidth + (barWidth * 0.1)
                let y = size.height - padding / 2 - barHeight

                let rect = CGRect(
                    x: x,
                    y: y,
                    width: barWidth - (barWidth * 0.2),
                    height: barHeight
                )

                let color = colors[index % colors.count]
                let fillColor: Color = (selectedBar == key) ? color : color.opacity(0.7)

                context.fill(
                    Path(roundedRect: rect, cornerRadius: 4),
                    with: .color(fillColor)
                )

                // X axis label
                var text = Text(key)
                    .font(.caption2)
                    .foregroundColor(.gray)
                context.draw(text, at: CGPoint(x: x + (barWidth - barWidth * 0.2) / 2, y: size.height - 15), anchor: .center)
            }
        }
    }

    // MARK: - Tooltip View
    @ViewBuilder
    private func tooltipView(for name: String, value: Double) -> some View {
        let total = distribution.values.reduce(0, +)
        let percentage = (value / total) * 100

        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.semibold)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Amount:")
                        .font(.caption)
                    Spacer()
                    Text(value.formatted(as: true))
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Percentage:")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.1f%%", percentage))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
        .padding()
    }

    // MARK: - Legend View
    @ViewBuilder
    private func legendView() -> some View {
        let total = distribution.values.reduce(0, +)

        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(distribution.sorted { $0.key < $1.key }.enumerated()), id: \.offset) { index, item in
                let percentage = (item.value / total) * 100

                HStack(spacing: 8) {
                    Circle()
                        .fill(colors[index % colors.count])
                        .frame(width: 12, height: 12)

                    Text(item.key)
                        .font(.subheadline)
                        .lineLimit(1)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.value.formatted(as: true))
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(String(format: "%.1f%%", percentage))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            }
        }
    }

    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: "chart.bar")
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
    private func updateSelectedBar(at location: CGPoint, in frame: CGRect) {
        let padding: CGFloat = 40
        let chartWidth = frame.width - (padding * 2)
        let barCount = distribution.count
        let barWidth = chartWidth / CGFloat(barCount)

        let normalizedX = (location.x - padding) / chartWidth
        let barIndex = Int(normalizedX * CGFloat(barCount))

        if barIndex >= 0 && barIndex < barCount {
            let sortedKeys = distribution.keys.sorted()
            selectedBar = sortedKeys[barIndex]
        }
    }

    private func formatYAxisLabel(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        } else {
            return "$\(Int(value))"
        }
    }
}

#Preview {
    let sampleData: [String: Double] = [
        "Pre-Tax": 150000,
        "Post-Tax": 100000
    ]

    AccountDistributionHistogram(
        distribution: sampleData,
        title: "Account Distribution"
    )
    .padding()
}
