import AppKit
import SwiftUI
import Carbon.HIToolbox

final class AppCoordinator: ObservableObject {
    static let shared = AppCoordinator()

    private let hotKey = HotKeyManager()
    private let selectionReader = SelectionReader()
    private let selectionMonitor = SelectionMonitor()
    private let clipboardMonitor = ClipboardMonitor()

    private var panel: NSPanel?
    private var toolbarPanel: SelectionToolbarPanel?
    private var lastSelectedText: String = ""

    private init() {}

    func start() {
        hotKey.register(command: true, shift: true, keyCode: UInt32(kVK_ANSI_E)) { [weak self] in
            self?.captureAndShow()
        }

        selectionMonitor.onSelection = { [weak self] text, location in
            NSLog("[SpeakPatch] selection detected: \(text.prefix(40))")
            self?.handleSelection(text: text, at: location, mode: .selection)
        }
        selectionMonitor.onEmpty = { [weak self] in
            self?.hideToolbar()
        }
        selectionMonitor.shouldReadSelection = {
            AppSettings.shared.autoToolbarEnabled && Accessibility.isTrusted
        }
        selectionMonitor.start()

        clipboardMonitor.onText = { [weak self] text, location in
            NSLog("[SpeakPatch] terminal clipboard detected: \(text.prefix(40))")
            self?.handleSelection(text: text, at: location, mode: .terminalClipboard)
        }
        clipboardMonitor.shouldMonitor = {
            AppSettings.shared.autoToolbarEnabled &&
                AppSettings.shared.terminalClipboardToolbarEnabled
        }
        clipboardMonitor.start()
        NSLog("[SpeakPatch] started. Accessibility trusted = \(Accessibility.isTrusted)")
    }

    // MARK: - Selection toolbar (PopClip-style)

    private func handleSelection(text: String, at location: NSPoint, mode: SelectionTriggerMode) {
        guard AppSettings.shared.autoToolbarEnabled else { return }
        guard let cleaned = SelectionCandidateFilter.cleanedText(from: text, mode: mode) else {
            hideToolbar()
            return
        }
        lastSelectedText = cleaned
        showToolbar(at: location)
    }

    func showToolbar(at location: NSPoint) {
        let actions: [RewriteAction] = [.fixGrammar, .natural, .translate]
        let view = SelectionToolbarView(
            actions: actions,
            onAction: { [weak self] action in
                self?.runFromToolbar(action)
            },
            onOpen: { [weak self] in
                self?.openPanelFromToolbar()
            }
        )

        let hosting = NSHostingView(rootView: view)
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize

        let panel: SelectionToolbarPanel
        if let existing = toolbarPanel {
            panel = existing
        } else {
            panel = SelectionToolbarPanel()
            toolbarPanel = panel
        }
        panel.setContentSize(size)
        panel.contentView = hosting
        positionToolbar(panel, near: location)
        panel.orderFrontRegardless()
    }

    private func positionToolbar(_ panel: NSPanel, near location: NSPoint) {
        let screen = NSScreen.screens.first { NSMouseInRect(location, $0.frame, false) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = panel.frame.size

        var x = location.x - size.width / 2
        var y = location.y + 18 // float just above the cursor
        x = max(visible.minX + 8, min(x, visible.maxX - size.width - 8))
        y = max(visible.minY + 8, min(y, visible.maxY - size.height - 8))
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func hideToolbar() {
        toolbarPanel?.orderOut(nil)
    }

    private func runFromToolbar(_ action: RewriteAction) {
        hideToolbar()
        let text = lastSelectedText
        Task { @MainActor in
            showPanel(selectedText: text, autoRun: action)
        }
    }

    private func openPanelFromToolbar() {
        hideToolbar()
        let text = lastSelectedText
        Task { @MainActor in
            showPanel(selectedText: text, autoRun: nil)
        }
    }

    // MARK: - Full rewrite panel

    func captureAndShow() {
        hideToolbar()
        clipboardMonitor.suppress(for: 1.0)
        Task { @MainActor in
            let selected = selectionReader.readSelectedTextViaClipboard()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            showPanel(selectedText: selected, autoRun: selected.isEmpty ? nil : .fixGrammar)
        }
    }

    @MainActor
    private func showPanel(selectedText: String, autoRun: RewriteAction?) {
        let view = RewritePanelView(initialText: selectedText, autoRunAction: autoRun)
            .environmentObject(AppSettings.shared)
        let hosting = NSHostingView(rootView: view)

        if panel == nil {
            let newPanel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: Theme.panelSize.width, height: Theme.panelSize.height))
            newPanel.contentView = hosting
            panel = newPanel
        } else {
            panel?.contentView = hosting
        }

        guard let panel else { return }
        position(panel: panel)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func position(panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = panel.frame.size
        var x = mouse.x - size.width / 2
        var y = mouse.y - size.height - 12
        x = max(visible.minX + 12, min(x, visible.maxX - size.width - 12))
        y = max(visible.minY + 12, min(y, visible.maxY - size.height - 12))
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

final class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed = false
        level = .floating
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backgroundColor = .clear
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        close()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if shouldClose(for: event) {
            close()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func keyDown(with event: NSEvent) {
        if shouldClose(for: event) {
            close()
            return
        }
        super.keyDown(with: event)
    }

    private func shouldClose(for event: NSEvent) -> Bool {
        if event.keyCode == UInt16(kVK_Escape) {
            return true
        }
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let blockedModifiers: NSEvent.ModifierFlags = [.control, .option]
        return modifiers.contains(.command) &&
            modifiers.intersection(blockedModifiers).isEmpty &&
            event.charactersIgnoringModifiers?.lowercased() == "w"
    }
}
