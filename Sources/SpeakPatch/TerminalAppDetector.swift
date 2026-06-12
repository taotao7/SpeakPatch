import AppKit

enum TerminalAppDetector {
    private static let terminalHints = [
        "ghostty",
        "terminal",
        "iterm",
        "wezterm",
        "alacritty",
        "kitty",
        "warp"
    ]

    static func isTerminal(_ app: NSRunningApplication? = NSWorkspace.shared.frontmostApplication) -> Bool {
        guard let app else { return false }
        let bundleID = app.bundleIdentifier?.lowercased() ?? ""
        let appName = app.localizedName?.lowercased() ?? ""
        return terminalHints.contains { bundleID.contains($0) || appName.contains($0) }
    }

    static func frontmostAppToken() -> String {
        guard let app = NSWorkspace.shared.frontmostApplication else { return "unknown" }
        return app.bundleIdentifier ?? app.localizedName ?? "unknown"
    }
}
