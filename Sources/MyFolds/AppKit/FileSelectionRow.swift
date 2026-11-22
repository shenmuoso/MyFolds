import AppKit

final class FileSelectionRow: NSTableRowView {
    weak var table: NSTableView?
    var accent: AppAccent = .system { didSet { updateTextColors(); needsDisplay = true } }
    override var isSelected: Bool { didSet { updateTextColors(); needsDisplay = true } }
    override var isEmphasized: Bool { didSet { updateTextColors(); needsDisplay = true } }
    override var interiorBackgroundStyle: NSView.BackgroundStyle { .normal }
    var selectionPalette: SelectionPalette { accent.palette(appearance: effectiveAppearance) }

    override func didAddSubview(_ subview: NSView) { super.didAddSubview(subview); updateTextColors() }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); updateTextColors(); needsDisplay = true }
    func updateTextColors() {
        for cell in subviews.compactMap({ $0 as? NSTableCellView }) {
            cell.backgroundStyle = .normal
            cell.textField?.textColor = isSelected && isEmphasized ? selectionPalette.foreground : cell.identifier?.rawValue == "name" ? .labelColor : .secondaryLabelColor
        }
    }
    override func drawDraggingDestinationFeedback(in dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 6, yRadius: 6)
        selectionPalette.background.withAlphaComponent(0.18).setFill(); path.fill()
        selectionPalette.background.setStroke(); path.lineWidth = 1.5; path.stroke()
    }
    override func drawSelection(in dirtyRect: NSRect) {
        guard let table else { return }
        let row = table.row(for: self)
        let joinsPrevious = row > 0 && table.isRowSelected(row - 1)
        let joinsNext = row + 1 < table.numberOfRows && table.isRowSelected(row + 1)
        let color = isEmphasized ? selectionPalette.background : selectionPalette.background.withAlphaComponent(0.20)
        color.setFill()
        let radius: CGFloat = 6
        NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius).fill()
        if joinsPrevious {
            NSRect(x: bounds.minX, y: isFlipped ? bounds.minY : bounds.maxY - radius, width: bounds.width, height: radius).fill()
        }
        if joinsNext {
            NSRect(x: bounds.minX, y: isFlipped ? bounds.maxY - radius : bounds.minY, width: bounds.width, height: radius).fill()
        }
    }
}
