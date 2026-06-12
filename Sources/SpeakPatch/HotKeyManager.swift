import Foundation
import Carbon

final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var callback: (() -> Void)?

    func register(command: Bool, shift: Bool, option: Bool = false, control: Bool = false, keyCode: UInt32, callback: @escaping () -> Void) {
        self.callback = callback
        var modifiers: UInt32 = 0
        if command { modifiers |= UInt32(cmdKey) }
        if shift { modifiers |= UInt32(shiftKey) }
        if option { modifiers |= UInt32(optionKey) }
        if control { modifiers |= UInt32(controlKey) }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData else { return noErr }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.callback?()
            return noErr
        }, 1, &eventType, selfPtr, &handlerRef)

        let signature = OSType(UInt32("SPHK".fourCharCodeValue))
        let id = EventHotKeyID(signature: signature, id: 1)
        RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}

private extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        for char in utf16.prefix(4) {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
}
