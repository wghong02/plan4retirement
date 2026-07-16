import Foundation
import SwiftUI

struct RetirementLineChart: View {
    let dataPoints: [ProjectionDataPoint]
    /// Recorded actual balances (past); drawn as a second line left of "today".
    var actualDataPoints: [ProjectionDataPoint] = []
    let title: String
    /// Calendar year/month corresponding to projection month 0. Defaults to today;
    /// saved snapshots pass the date they were created so their axis stays fixed.
    var startYear: Int = Calendar.current.component(.year, from: Date())
    var startMonth: Int = Calendar.current.component(.month, from: Date())
    /// How many months / years to show in each display mode.
    var maxMonths: Int = 60
    var maxYears: Int = 100
    /// When true, balances/contributions are deflated to today's dollars.
    var inflationAdjusted: Bool = false
    var inflationRate: Double = 0
    let height: CGFloat = 350

    @State private var selectedMonth: Int? = nil
    // Pinch zoom on the x-axis. `zoomScale` is the committed zoom; `pinchScale`
    // and `pinchAnchor` track the in-flight gesture so the month under the
    // pinch stays fixed on screen while zooming.
    @State private var zoomScale: CGFloat = 1
    @State private var pinchScale: CGFloat = 1
    @State private var pinchAnchor: (month: Double, fraction: Double)? = nil
    // Pan (drag-while-zoomed). `centerMonth` is the committed window center
    // (nil = center of the full range); `dragWidthLive` tracks the in-flight
    // drag in points and is converted to months for display.
    @State private var centerMonth: Double? = nil
    @GestureState private var dragWidthLive: CGFloat = 0
    @State private var lastChartWidth: CGFloat = 300
    @Binding var displayMode: DisplayMode

    private let maxZoom: CGFloat = 24

    enum DisplayMode {
        case monthly
        case yearly
    }

    private static let monthAbbreviations = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]

    private let padding: CGFloat = 50

    // MARK: - Filtered series

    private func adjusted(_ points: [ProjectionDataPoint]) -> [ProjectionDataPoint] {
        guard inflationAdjusted, inflationRate != 0 else { return points }
        let rate = inflationRate / 100.0
        return points.map { point in
            let factor = pow(1 + rate, Double(point.monthIndex) / 12.0)
            return ProjectionDataPoint(
                monthIndex: point.monthIndex,
                age: point.age,
                balance: point.balance / factor,
                contribution: point.contribution / factor,
                growth: point.growth / factor
            )
        }
    }

    private var projectedFiltered: [ProjectionDataPoint] {
        let base: [ProjectionDataPoint]
        switch displayMode {
        case .monthly:
            base = Array(dataPoints.prefix(maxMonths))
        case .yearly:
            base = Array(dataPoints.filter { $0.monthIndex % 12 == 0 }.prefix(maxYears))
        }
        return adjusted(base)
    }

    private var actualFiltered: [ProjectionDataPoint] {
        guard !actualDataPoints.isEmpty else { return [] }
        let base: [ProjectionDataPoint]
        switch displayMode {
        case .monthly:
            base = actualDataPoints
        case .yearly:
            var pts = actualDataPoints.filter { $0.monthIndex % 12 == 0 }
            // Ensure the earliest actual shows even when history is under a year.
            if let earliest = actualDataPoints.first, pts.first?.monthIndex != earliest.monthIndex {
                pts.insert(earliest, at: 0)
            }
            base = pts
        }
        return adjusted(base)
    }

    private var visibleMonthRange: (min: Int, max: Int)? {
        let all = projectedFiltered + actualFiltered
        guard let lo = all.map(\.monthIndex).min(), let hi = all.map(\.monthIndex).max() else { return nil }
        return (lo, hi)
    }

    private func spanForZoom(_ zoom: CGFloat, fullSpan: Int) -> Int {
        let minSpan = displayMode == .monthly ? 6 : 48 // don't zoom past ~6 points
        return max(minSpan, Int(CGFloat(fullSpan) / max(1, zoom)))
    }

    /// The full month range narrowed by the current pinch zoom, centered on
    /// `centerMonth` (default: middle of the visible range) and shifted by any
    /// in-flight pan drag. The y-axis rescales automatically to the visible points.
    private var zoomedMonthRange: (min: Int, max: Int)? {
        guard let full = visibleMonthRange else { return nil }
        let zoom = min(max(zoomScale * pinchScale, 1), maxZoom)
        guard zoom > 1.001 else { return full }

        let fullSpan = max(1, full.max - full.min)
        let span = spanForZoom(zoom, fullSpan: fullSpan)

        var center: Double
        if let pinchAnchor {
            // Keep the month under the pinch at the same horizontal position
            // while the span shrinks/grows around it.
            center = pinchAnchor.month + (0.5 - pinchAnchor.fraction) * Double(span)
        } else {
            center = centerMonth ?? Double(full.min + full.max) / 2
        }

        // Live drag in points → months (drag right shows earlier months).
        // Suppressed while scrubbing the tooltip or pinching.
        if selectedMonth == nil, pinchAnchor == nil, dragWidthLive != 0 {
            let chartWidth = max(1, lastChartWidth - padding * 2)
            center -= Double(dragWidthLive / chartWidth) * Double(span)
        }

        center = min(max(center, Double(full.min) + Double(span) / 2), Double(full.max) - Double(span) / 2)

        var start = Int((center - Double(span) / 2).rounded())
        start = min(max(start, full.min), full.max - span)
        return (start, start + span)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            if projectedFiltered.isEmpty && actualFiltered.isEmpty {
                emptyStateView()
            } else {
                // Detail requires a press-and-hold so a plain drag still scrolls.
                GeometryReader { geo in
                    ZStack {
                        canvas
                            .gesture(
                                LongPressGesture(minimumDuration: 0.2)
                                    .sequenced(before: DragGesture(minimumDistance: 0))
                                    .onChanged { value in
                                        if case .second(true, let drag?) = value {
                                            updateSelection(at: drag.location, in: geo.size)
                                        }
                                    }
                                    .onEnded { _ in selectedMonth = nil }
                            )
                            // Pinch to zoom the x-axis, anchored at the pinch location;
                            // double-tap resets to the full range.
                            .simultaneousGesture(
                                MagnifyGesture()
                                    .onChanged { value in
                                        if pinchAnchor == nil, let range = zoomedMonthRange {
                                            // Month under the fingers when the pinch began.
                                            let chartWidth = max(1, lastChartWidth - padding * 2)
                                            let viewX = value.startAnchor.x * lastChartWidth
                                            let fraction = Double(min(max((viewX - padding) / chartWidth, 0), 1))
                                            let month = Double(range.min) + fraction * Double(range.max - range.min)
                                            pinchAnchor = (month, fraction)
                                        }
                                        pinchScale = value.magnification
                                    }
                                    .onEnded { value in
                                        // Freeze the window where the pinch left it, then commit.
                                        let finalRange = zoomedMonthRange
                                        zoomScale = min(max(zoomScale * value.magnification, 1), maxZoom)
                                        pinchAnchor = nil
                                        pinchScale = 1
                                        if zoomScale <= 1.001 {
                                            zoomScale = 1
                                            centerMonth = nil
                                        } else if let finalRange {
                                            centerMonth = Double(finalRange.min + finalRange.max) / 2
                                        }
                                    }
                            )
                            // Drag to pan when zoomed in. High priority so the page
                            // ScrollView doesn't swallow the drag; the mask disables
                            // it entirely at 1x so normal scrolling still works.
                            .highPriorityGesture(
                                DragGesture(minimumDistance: 12)
                                    .updating($dragWidthLive) { value, state, _ in
                                        if zoomScale > 1 { state = value.translation.width }
                                    }
                                    .onEnded { value in
                                        commitPan(translation: value.translation.width, width: geo.size.width)
                                    },
                                including: zoomScale > 1 ? .all : .subviews
                            )
                            .onTapGesture(count: 2) {
                                zoomScale = 1
                                pinchScale = 1
                                pinchAnchor = nil
                                centerMonth = nil
                            }

                        if let point = selectedPoint {
                            tooltipView(for: point)
                        }
                    }
                    .onAppear { lastChartWidth = geo.size.width }
                    .onChange(of: geo.size.width) { lastChartWidth = $0 }
                }
                .frame(height: height)
                // Darker shade signals this area is interactive (press-and-hold), not scrollable.
                .background(Color(.systemGray4))
                .cornerRadius(8)
                .onChange(of: displayMode) { _ in
                    zoomScale = 1
                    pinchScale = 1
                    pinchAnchor = nil
                    centerMonth = nil
                }

                legendView()
                statsView()
            }
        }
    }

    // MARK: - Canvas View
    private var canvas: some View {
        Canvas { context, size in
            guard let range = zoomedMonthRange else { return }
            // Only the points inside the zoom window are drawn, so the y-scale
            // below automatically fits the visible slice.
            let projected = projectedFiltered.filter { (range.min...range.max).contains($0.monthIndex) }
            let actual = actualFiltered.filter { (range.min...range.max).contains($0.monthIndex) }
            let all = projected + actual
            guard !all.isEmpty else { return }

            let maxBalance = all.map(\.balance).max() ?? 100000
            let minBalance = all.map(\.balance).min() ?? 0
            let balanceRange = max(1, maxBalance - minBalance)
            let monthSpan = max(1, range.max - range.min)
            let chartWidth = size.width - (padding * 2)
            let chartHeight = size.height - (padding * 1.5)

            func xFor(_ monthIndex: Int) -> CGFloat {
                padding + CGFloat(monthIndex - range.min) / CGFloat(monthSpan) * chartWidth
            }
            func yFor(_ balance: Double) -> CGFloat {
                let norm = (balance - minBalance) / balanceRange
                return size.height - padding / 2 - norm * chartHeight
            }

            // Axes
            var yPath = Path()
            yPath.move(to: CGPoint(x: padding, y: padding))
            yPath.addLine(to: CGPoint(x: padding, y: size.height - padding / 2))
            context.stroke(yPath, with: .color(.gray), lineWidth: 1)

            var xPath = Path()
            xPath.move(to: CGPoint(x: padding, y: size.height - padding / 2))
            xPath.addLine(to: CGPoint(x: size.width - padding, y: size.height - padding / 2))
            context.stroke(xPath, with: .color(.gray), lineWidth: 1)

            // Grid + Y labels
            for i in stride(from: 0, through: 4, by: 1) {
                let y = padding + CGFloat(i) * (chartHeight / 4)
                let balance = maxBalance - (Double(i) / 4.0) * (maxBalance - minBalance)

                var gridPath = Path()
                gridPath.move(to: CGPoint(x: padding, y: y))
                gridPath.addLine(to: CGPoint(x: size.width - padding, y: y))
                context.stroke(gridPath, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)

                let text = Text(balance.formattedAsAxisLabel())
                    .font(.caption2)
                    .foregroundColor(.gray)
                context.draw(text, at: CGPoint(x: padding - 40, y: y), anchor: .center)
            }

            // "Today" marker when there is past history to the left
            if range.min < 0 && range.max >= 0 {
                let x0 = xFor(0)
                var todayPath = Path()
                todayPath.move(to: CGPoint(x: x0, y: padding))
                todayPath.addLine(to: CGPoint(x: x0, y: size.height - padding / 2))
                context.stroke(todayPath, with: .color(.gray.opacity(0.5)), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }

            let selMonth = selectedPoint?.monthIndex

            func draw(_ points: [ProjectionDataPoint], color: Color) {
                guard !points.isEmpty else { return }
                var line = Path()
                for (i, p) in points.enumerated() {
                    let pt = CGPoint(x: xFor(p.monthIndex), y: yFor(p.balance))
                    if i == 0 { line.move(to: pt) } else { line.addLine(to: pt) }
                }
                context.stroke(line, with: .color(color), lineWidth: 2)

                for p in points {
                    let pt = CGPoint(x: xFor(p.monthIndex), y: yFor(p.balance))
                    let selected = (p.monthIndex == selMonth)
                    let r: CGFloat = selected ? 5 : 3
                    context.fill(
                        Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)),
                        with: .color(selected ? color : color.opacity(0.6))
                    )
                }
            }

            // Actual (past) behind, projected (future) on top.
            draw(actual, color: .green)
            draw(projected, color: .blue)

            // X labels
            let step = max(1, monthSpan / 6)
            for monthIndex in stride(from: range.min, through: range.max, by: step) {
                let x = xFor(monthIndex)
                let text = Text(verbatim: xAxisLabel(monthIndex: monthIndex))
                    .font(.caption2)
                    .foregroundColor(.gray)
                context.draw(text, at: CGPoint(x: x, y: size.height - 20), anchor: .center)
            }
        }
    }

    // MARK: - Tooltip
    private var selectedPoint: ProjectionDataPoint? {
        guard let selectedMonth else { return nil }
        let all = projectedFiltered + actualFiltered
        return all.min(by: { abs($0.monthIndex - selectedMonth) < abs($1.monthIndex - selectedMonth) })
    }

    @ViewBuilder
    private func tooltipView(for point: ProjectionDataPoint) -> some View {
        let isActual = point.monthIndex < 0
        let isYearly = displayMode == .yearly
        let periodMultiplier: Double = isYearly ? 12 : 1
        let contributionLabel = isYearly ? "Annual Contribution:" : "Monthly Contribution:"
        let growthLabel = isYearly ? "Annual Growth:" : "Monthly Growth:"

        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: periodLabel(monthIndex: point.monthIndex) + (isActual ? " (actual)" : ""))
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

            if !isActual {
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
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
        .padding()
    }

    // MARK: - Legend
    @ViewBuilder
    private func legendView() -> some View {
        if !actualFiltered.isEmpty {
            HStack(spacing: 16) {
                Label("Actual", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                Label("Projected", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                Spacer()
            }
        }
    }

    // MARK: - Stats
    @ViewBuilder
    private func statsView() -> some View {
        let startingBalance = (actualFiltered.first ?? projectedFiltered.first)?.balance ?? 0
        let endingBalance = projectedFiltered.last?.balance ?? 0

        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Starting")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(startingBalance.formatted(as: true))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Ending")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(endingBalance.formatted(as: true))
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

    /// Commits an in-flight pan drag into `centerMonth`, clamped so the window
    /// stays within the data.
    private func commitPan(translation: CGFloat, width: CGFloat) {
        guard zoomScale > 1, selectedMonth == nil, let full = visibleMonthRange else { return }
        let fullSpan = max(1, full.max - full.min)
        let span = spanForZoom(min(max(zoomScale, 1), maxZoom), fullSpan: fullSpan)
        let chartWidth = max(1, width - padding * 2)

        var center = centerMonth ?? Double(full.min + full.max) / 2
        center -= Double(translation / chartWidth) * Double(span)
        center = min(max(center, Double(full.min) + Double(span) / 2), Double(full.max) - Double(span) / 2)
        centerMonth = center
    }

    // MARK: - Helpers
    private func updateSelection(at location: CGPoint, in size: CGSize) {
        guard let range = zoomedMonthRange else { return }
        let chartWidth = size.width - (padding * 2)
        guard chartWidth > 0 else { return }
        let span = max(1, range.max - range.min)
        let normalizedX = (location.x - padding) / chartWidth
        let monthIndex = range.min + Int((normalizedX * CGFloat(span)).rounded())
        selectedMonth = min(max(monthIndex, range.min), range.max)
    }

    /// Compact axis label: calendar year in yearly mode, "MMM YY" in monthly mode.
    private func xAxisLabel(monthIndex: Int) -> String {
        let (year, month) = calendarComponents(monthIndex: monthIndex)
        switch displayMode {
        case .yearly: return "\(year)"
        case .monthly: return "\(Self.monthAbbreviations[month]) \(year % 100)"
        }
    }

    /// Full label used in the tooltip header.
    private func periodLabel(monthIndex: Int) -> String {
        let (year, month) = calendarComponents(monthIndex: monthIndex)
        switch displayMode {
        case .yearly: return "\(year)"
        case .monthly: return "\(Self.monthAbbreviations[month]) \(year)"
        }
    }

    /// Absolute (year, 0-based month) for a month offset, handling negative offsets.
    private func calendarComponents(monthIndex: Int) -> (year: Int, month: Int) {
        let absoluteMonth = (startMonth - 1) + monthIndex
        let year = startYear + Int(floor(Double(absoluteMonth) / 12.0))
        let month = ((absoluteMonth % 12) + 12) % 12
        return (year, month)
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
