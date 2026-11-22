import AppKit

final class FileTableContainer: NSView {
    let scroll = FileScrollView()
    let header = FrostedTableHeader()
    weak var table: NSTableView?
    private var lastWidth: CGFloat = 0
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        header.translatesAutoresizingMaskIntoConstraints = false
        addSubview(header); addSubview(scroll)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor), header.leadingAnchor.constraint(equalTo: leadingAnchor), header.trailingAnchor.constraint(equalTo: trailingAnchor), header.heightAnchor.constraint(equalToConstant: 36),
            scroll.topAnchor.constraint(equalTo: header.bottomAnchor), scroll.leadingAnchor.constraint(equalTo: leadingAnchor), scroll.trailingAnchor.constraint(equalTo: trailingAnchor), scroll.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
    override func layout() {
        super.layout()
        guard let table, bounds.width > 0, abs(bounds.width - lastWidth) > 1 else { return }
        lastWidth = bounds.width
        for (column, fraction) in zip(table.tableColumns, [0.50, 0.24, 0.13, 0.13]) { column.width = max(column.minWidth, bounds.width * fraction) }
        header.needsDisplay = true
    }
}
