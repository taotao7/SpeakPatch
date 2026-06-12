import AppKit
import Carbon.HIToolbox

final class SelectionReader {
    func readSelectedTextViaClipboard() -> String {
        let pasteboard = NSPasteboard.general
        let oldItems = pasteboard.pasteboardItems?.map { item -> NSPasteboardItem in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        }

        sendCopyShortcut()
        Thread.sleep(forTimeInterval: 0.12)
        let text = pasteboard.string(forType: .string) ?? ""

        if let oldItems {
            pasteboard.clearContents()
            pasteboard.writeObjects(oldItems)
        }
        return text
    }

    private func sendCopyShortcut() {
        guard Accessibility.ensurePermission(prompt: true) else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
