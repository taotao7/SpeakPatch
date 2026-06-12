import AppKit

final class ClipboardMonitor {
    var onText: ((String, NSPoint) -> Void)?
    var shouldMonitor: () -> Bool = { true }

    private var timer: Timer?
    private var debounceWorkItem: DispatchWorkItem?
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var suppressUntil = Date.distantPast
    private var lastAcceptedKey: String?
    private var lastAcceptedAt = Date.distantPast

    func start() {
        guard timer == nil else { return }
        lastChangeCount = NSPasteboard.general.changeCount
        let newTimer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.poll()
        }
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
    }

    func suppress(for duration: TimeInterval = 1.0) {
        suppressUntil = Date().addingTimeInterval(duration)
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        lastChangeCount = NSPasteboard.general.changeCount
    }

    private func poll() {
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount

        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.handleDebouncedChange()
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    private func handleDebouncedChange() {
        guard Date() >= suppressUntil,
              shouldMonitor(),
              TerminalAppDetector.isTerminal(),
              let rawText = NSPasteboard.general.string(forType: .string),
              let text = SelectionCandidateFilter.cleanedText(from: rawText, mode: .terminalClipboard),
              shouldAcceptDeduped(text) else {
            return
        }

        onText?(text, NSEvent.mouseLocation)
    }

    private func shouldAcceptDeduped(_ text: String) -> Bool {
        let key = "\(TerminalAppDetector.frontmostAppToken())|\(SelectionCandidateFilter.normalizedKey(for: text))"
        let now = Date()
        if key == lastAcceptedKey, now.timeIntervalSince(lastAcceptedAt) < 1.0 {
            return false
        }
        lastAcceptedKey = key
        lastAcceptedAt = now
        return true
    }
}
