import AppKit
import MyFoldsCore

final class EditorTextView: NSTextView {
    @discardableResult
    func apply(_ plan: TextReplacementPlan, actionName: String) -> Bool {
        guard !hasMarkedText(), isEditable, NSMaxRange(plan.range) <= (string as NSString).length else { return false }
        breakUndoCoalescing()
        undoManager?.beginUndoGrouping()
        guard shouldChangeText(in: plan.range, replacementString: plan.replacement) else { undoManager?.endUndoGrouping(); return false }
        textStorage?.replaceCharacters(in: plan.range, with: plan.replacement)
        didChangeText()
        setSelectedRange(NSRange(location: plan.range.location + (plan.replacement as NSString).length, length: 0))
        undoManager?.endUndoGrouping()
        undoManager?.setActionName(actionName)
        breakUndoCoalescing()
        return true
    }
}
