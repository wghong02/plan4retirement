import Foundation
import OSLog

/// Lightweight wrapper over the unified logging system, so views can report
/// recoverable errors without each importing OSLog or holding a `Logger`.
enum AppLog {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Plan4Retirement",
        category: "app"
    )

    /// Logs a recoverable error to the unified logging system (visible in Console.app).
    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
