import AppKit
import SwiftUI

struct EditorShortcut: Codable, Equatable, Sendable {
    var key: String
    var command = true
    var control = false
    var option = false
    var shift = false
    static let find = Self(key: "f")
    static let replace = Self(key: "r")
    var modifiers: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if command { flags.insert(.command) }; if control { flags.insert(.control) }
        if option { flags.insert(.option) }; if shift { flags.insert(.shift) }
        return flags
    }
    var eventModifiers: EventModifiers {
        var flags: EventModifiers = []
        if command { flags.insert(.command) }; if control { flags.insert(.control) }
        if option { flags.insert(.option) }; if shift { flags.insert(.shift) }
        return flags
    }
    var equivalent: KeyEquivalent { KeyEquivalent(key.first ?? "f") }
    var label: String { (control ? "⌃" : "") + (option ? "⌥" : "") + (shift ? "⇧" : "") + (command ? "⌘" : "") + key.uppercased() }
    var validationError: String? {
        guard key.count == 1, let character = key.first, character.isASCII, character.isLetter || character.isNumber, command || control else { return "请使用 Command 或 Control 加一个字母或数字。" }
        if command && !control && !option && !shift && "aswxzcvqohmtnlg".contains(key) { return "这个组合已用于应用的常用操作，请选择其他快捷键。" }
        if command && !control && !option && shift && "sngh".contains(key) { return "这个组合已用于应用的常用操作，请选择其他快捷键。" }
        if command && !control && option && !shift && "cdp".contains(key) { return "这个组合已用于应用的常用操作，请选择其他快捷键。" }
        return nil
    }
    init(key: String, command: Bool = true, control: Bool = false, option: Bool = false, shift: Bool = false) {
        self.key = key.lowercased(); self.command = command; self.control = control; self.option = option; self.shift = shift
    }
    init?(event: NSEvent) {
        guard let key = event.charactersIgnoringModifiers?.lowercased(), key.count == 1 else { return nil }
        self.init(key: key, command: event.modifierFlags.contains(.command), control: event.modifierFlags.contains(.control), option: event.modifierFlags.contains(.option), shift: event.modifierFlags.contains(.shift))
    }
    func matches(_ event: NSEvent) -> Bool {
        event.charactersIgnoringModifiers?.lowercased() == key && event.modifierFlags.intersection([.command, .control, .option, .shift]) == modifiers
    }
}
