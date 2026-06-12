import AppKit
import Carbon.HIToolbox

final class SelectionReader {
    func readSelectedTextViaClipboard(promptForPermission: Bool = true) -> String {
        let pasteboard = NSPasteboard.general
        let previousChangeCount = pasteboard.changeCount
        let oldItems = pasteboard.pasteboardItems?.map { item -> NSPasteboardItem in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        }

        guard sendCopyShortcut(promptForPermission: promptForPermission) else {
            return ""
        }

        let deadline = Date().addingTimeInterval(0.35)
        while pasteboard.changeCount == previousChangeCount && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
        }

        let didCopySelection = pasteboard.changeCount != previousChangeCount
        let text = didCopySelection ? (pasteboard.string(forType: .string) ?? "") : ""

        if didCopySelection {
            pasteboard.clearContents()
            if let oldItems, !oldItems.isEmpty {
                pasteboard.writeObjects(oldItems)
            }
        }
        return text
    }

    @discardableResult
    private func sendCopyShortcut(promptForPermission: Bool) -> Bool {
        guard Accessibility.ensurePermission(prompt: promptForPermission) else { return false }
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        return true
    }
}
