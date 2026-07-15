import SwiftUI

/// Integer entry that supports both direct typing and +/- stepper buttons,
/// with an inline red warning when the value is out of range.
struct StepperField: View {
    let title: String
    @Binding var text: String
    let range: ClosedRange<Int>
    var focus: FocusState<Bool>.Binding
    var isValid: Bool
    var errorMessage: String = "Please enter a number within the bound"

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                TextField("", text: $text)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
                    .focused(focus)
                Stepper("", onIncrement: { adjust(1) }, onDecrement: { adjust(-1) })
                    .labelsHidden()
            }
            if !isValid {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private func adjust(_ delta: Int) {
        let current = Int(text) ?? range.lowerBound
        let next = min(max(current + delta, range.lowerBound), range.upperBound)
        text = "\(next)"
    }
}

/// Decimal entry backed by a plain string (so typing decimal points is never
/// swallowed by a live formatter), with an inline red warning.
struct DecimalField: View {
    let title: String
    @Binding var text: String
    var suffix: String? = nil
    var focus: FocusState<Bool>.Binding
    var isValid: Bool
    var errorMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                TextField("", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 110)
                    .focused(focus)
                if let suffix {
                    Text(suffix)
                        .foregroundColor(.gray)
                }
            }
            if !isValid {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}
