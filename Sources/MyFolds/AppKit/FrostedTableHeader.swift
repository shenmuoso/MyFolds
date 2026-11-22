import AppKit

final class FrostedTableHeader: NSTableHeaderView {
    override var isOpaque: Bool { false }
    override func draw(_ dirtyRect: NSRect) {
        guard let tableView else { return }
        for (index, column) in tableView.tableColumns.enumerated() where !column.isHidden {
            var rect = headerRect(ofColumn: index)
            rect.origin.x += 10; rect.size.width -= 20
            let text = column.title as NSString
            let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor]
            let size = text.size(withAttributes: attributes)
            text.draw(at: NSPoint(x: rect.minX, y: (bounds.height - size.height) / 2 + 2), withAttributes: attributes)
            if let descriptor = tableView.sortDescriptors.first, descriptor.key == column.identifier.rawValue,
               let symbol = NSImage(systemSymbolName: descriptor.ascending ? "chevron.up" : "chevron.down", accessibilityDescription: nil)?.withSymbolConfiguration(.init(pointSize: 8, weight: .regular)) {
                symbol.draw(in: NSRect(x: rect.minX + size.width + 4, y: (bounds.height - 8) / 2 + 2, width: 8, height: 8))
            }
        }
    }
}
