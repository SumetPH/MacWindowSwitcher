import os

extension Logger {
    /// Subsystem matches the app bundle id so logs can be filtered in Console.
    static let subsystem = "dev.sumetph.MacWindowSwitcher"

    static func forCategory(_ category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}
