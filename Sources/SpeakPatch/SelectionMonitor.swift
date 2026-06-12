import AppKit

/// Watches for text selections in other applications. On every left mouse-up
/// (the gesture that finishes a drag-selection or double-click), it reads the
/// focused element's selected text via the Accessibility API and reports it.
///
/// Global event monitors only receive events destined for *other* apps, so
/// clicks inside SpeakPatch's own panels never trigger this.
final class SelectionMonitor {
    var onSelection: ((String, NSPoint) -> Void)?
    var onEmpty: (() -> Void)?

    private var monitor: Any?

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            self?.handleMouseUp()
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    private func handleMouseUp() {
        // Give the source app a beat to finalize its selection before we read it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
            guard let self else { return }
            if let text = Accessibility.selectedText() {
                self.onSelection?(text, NSEvent.mouseLocation)
            } else {
                self.onEmpty?()
            }
        }
    }
}
