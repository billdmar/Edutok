/// AppLog.swift
///
/// Thin wrapper over Apple's unified logging (`os.Logger`, iOS 14+). Replaces ad-hoc
/// `print` calls so diagnostics go through the system log (filterable by subsystem/category
/// in Console.app, automatically excluded from release log streams unless explicitly viewed)
/// instead of stdout. Categories group messages by area.
import Foundation
import os

enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "dh.Edutok"

    /// Logical areas, so logs can be filtered by category in Console.app.
    enum Category: String {
        case network = "Network"
        case persistence = "Persistence"
        case auth = "Auth"
        case gamification = "Gamification"
        case general = "General"
    }

    private static func logger(_ category: Category) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }

    /// An error worth recording in release builds (failures, fallbacks, dropped data).
    static func error(_ message: String, category: Category = .general) {
        logger(category).error("\(message, privacy: .public)")
    }

    /// Diagnostic detail useful while developing; persisted by the system at debug level.
    static func debug(_ message: String, category: Category = .general) {
        logger(category).debug("\(message, privacy: .public)")
    }
}
