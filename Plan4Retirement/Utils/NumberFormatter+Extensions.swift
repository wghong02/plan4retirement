import Foundation

extension Double {
    func formatted(as currency: Bool = true) -> String {
        if currency {
            return NumberFormatter.currencyFormatter.string(from: NSNumber(value: self)) ?? "$0.00"
        } else {
            return NumberFormatter.decimalFormatter.string(from: NSNumber(value: self)) ?? "0.00"
        }
    }

    func formattedAsPercentage() -> String {
        return String(format: "%.2f%%", self)
    }

    /// Compact currency label for chart axes, e.g. "$1.2M", "$45K", "$500".
    func formattedAsAxisLabel() -> String {
        if self >= 1_000_000 {
            return String(format: "$%.1fM", self / 1_000_000)
        } else if self >= 1_000 {
            return String(format: "$%.0fK", self / 1_000)
        } else {
            return "$\(Int(self))"
        }
    }
}

extension NumberFormatter {
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()

    static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
