import SwiftUI

extension View {
    /// Standard card container used throughout the app: padded content on a
    /// light gray rounded background.
    func cardStyle(cornerRadius: CGFloat = 12) -> some View {
        self
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(cornerRadius)
    }
}
