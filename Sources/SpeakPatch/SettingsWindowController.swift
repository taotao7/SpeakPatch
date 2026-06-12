import AppKit
import SwiftUI

/// Manages a single Settings window manually. In an `.accessory` (menu-bar)
/// app the SwiftUI `Settings` scene + `showSettingsWindow:` selector is
/// unreliable and often silently fails to bring a window forward, so we own
/// the window directly instead.
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    func show() {
        if window == nil {
            let view = SettingsView().environmentObject(AppSettings.shared)
            let hosting = NSHostingController(rootView: view)
            let win = NSWindow(contentViewController: hosting)
            win.title = "SpeakPatch Settings"
            win.styleMask = [.titled, .closable, .miniaturizable]
            win.isReleasedWhenClosed = false
            win.center()
            window = win
        }

        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }
}
