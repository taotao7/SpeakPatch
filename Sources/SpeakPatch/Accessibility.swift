import AppKit

struct Accessibility {
    static var isTrusted: Bool {
        ensurePermission(prompt: false)
    }

    static func ensurePermission(prompt: Bool) -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Reads the currently selected text from the focused UI element via the
    /// Accessibility API, without touching the clipboard. Returns nil if there
    /// is no selection or the focused app doesn't expose selected text over AX.
    static func selectedText() -> String? {
        let system = AXUIElementCreateSystemWide()

        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let focusedElement = focused else {
            return nil
        }
        let element = focusedElement as! AXUIElement

        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &value) == .success,
              let text = value as? String else {
            return nil
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
