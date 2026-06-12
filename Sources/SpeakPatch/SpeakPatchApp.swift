import SwiftUI
import AppKit

@main
struct SpeakPatchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Settings are presented via SettingsWindowController; this scene only
        // satisfies the App protocol's requirement for at least one Scene.
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let coordinator = AppCoordinator.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        coordinator.start()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "SP"
        item.button?.toolTip = "SpeakPatch"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Rewrite Selected Text", action: #selector(rewriteSelected), keyEquivalent: "e"))

        let toggle = NSMenuItem(title: "Show Toolbar on Selection", action: #selector(toggleAutoToolbar), keyEquivalent: "")
        toggle.state = AppSettings.shared.autoToolbarEnabled ? .on : .off
        menu.addItem(toggle)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    @objc private func rewriteSelected() {
        coordinator.captureAndShow()
    }

    @objc private func toggleAutoToolbar(_ sender: NSMenuItem) {
        AppSettings.shared.autoToolbarEnabled.toggle()
        sender.state = AppSettings.shared.autoToolbarEnabled ? .on : .off
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
