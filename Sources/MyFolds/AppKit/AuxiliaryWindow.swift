import AppKit

final class AuxiliaryWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) { performClose(sender) }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { performClose(nil) }
        else { super.keyDown(with: event) }
    }
}
