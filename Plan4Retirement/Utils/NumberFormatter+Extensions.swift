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

    /// String for pre-filling editable text fields: whole numbers drop the trailing ".0".
    var fieldText: String {
        self == rounded() ? String(Int(self)) : String(self)
    }

    /// Deflates a future amount to today's dollars at an annual inflation rate (in percent).
    func deflated(byAnnualRate percent: Double, overYears years: Double) -> Double {
        guard percent != 0 else { return self }
        return self / pow(1 + percent / 100.0, years)
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
}
