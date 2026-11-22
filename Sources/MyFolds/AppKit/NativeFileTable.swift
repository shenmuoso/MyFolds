import SwiftUI
import MyFoldsCore
import UniformTypeIdentifiers

struct NativeFileTable: NSViewRepresentable {
    let items: [FileItem]
    @Binding var selection: Set<URL>
    let model: BrowserModel
    let session: FolderSession
    let isRight: Bool
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> FileTableContainer {
        let container = FileTableContainer(); let scroll = container.scroll; scroll.hasVerticalScroller = true; scroll.drawsBackground = false
        let table = BrowserTable(); table.backgroundColor = .clear
        table.style = .plain
        table.headerView = nil
        container.header.tableView = table; container.table = table
        table.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        scroll.borderType = .noBorder; scroll.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0); scroll.automaticallyAdjustsContentInsets = false
        table.allowsMultipleSelection = true; table.allowsEmptySelection = true
        table.intercellSpacing = NSSize(width: 0, height: 0); table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        table.gridStyleMask = []; table.usesAlternatingRowBackgroundColors = false
        for (key, title, width) in [("name", "名称", 280.0), ("modified", "修改日期", 140.0), ("kind", "类型", 110.0), ("size", "大小", 80.0)] {
            let column = NSTableColumn(identifier: .init(key)); column.title = title; column.width = width
            column.minWidth = key == "name" ? 160 : 65
            column.sortDescriptorPrototype = NSSortDescriptor(key: key, ascending: true)
            table.addTableColumn(column)
        }
        table.delegate = context.coordinator; table.dataSource = context.coordinator
        table.target = context.coordinator; table.doubleAction = #selector(Coordinator.openItem)
        table.registerForDraggedTypes([.fileURL])
        table.setDraggingSourceOperationMask(.copy, forLocal: false)
        table.setDraggingSourceOperationMask(.copy, forLocal: true)
        table.previewAction = model.quickLook; table.renameAction = { model.requestName(rename: true) }
        table.activateAction = { model.rightActive = isRight }
        table.contextMenuProvider = { [weak coordinator = context.coordinator, weak table] index in
            guard let parent = coordinator?.parent else { return NSMenu() }
            let item = index >= 0 && index < parent.items.count ? parent.items[index] : nil
            return FileMenuFactory.make(model: parent.model, session: parent.session, item: item, window: table?.window)
        }
        scroll.blankMenu = { [weak coordinator = context.coordinator, weak scroll] in
            guard let parent = coordinator?.parent else { return NSMenu() }
            return FileMenuFactory.make(model: parent.model, session: parent.session, item: nil, window: scroll?.window)
        }
        scroll.documentView = table
        context.coordinator.table = table
        return container
    }
    func updateNSView(_ container: FileTableContainer, context: Context) {
        let scroll = container.scroll
        guard let table = scroll.documentView as? BrowserTable else { return }
        context.coordinator.parent = self
        context.coordinator.syncing = true
        defer { context.coordinator.syncing = false }
        table.rowHeight = model.preferences.compact ? 28 : 35
        if context.coordinator.cachedItems != items {
            context.coordinator.cachedItems = items
            table.reloadData()
        }
        let indices = IndexSet(items.indices.filter { selection.contains(items[$0].url) })
        if table.selectedRowIndexes != indices { table.selectRowIndexes(indices, byExtendingSelection: false) }
        let width = scroll.contentSize.width
        if width > 0 && abs(context.coordinator.cachedWidth - width) > 1 {
            context.coordinator.cachedWidth = width
            for (column, fraction) in zip(table.tableColumns, [0.50, 0.24, 0.13, 0.13]) { column.width = max(column.minWidth, width * fraction) }
        }
        container.header.needsDisplay = true
        table.needsDisplay = true
        let accent = model.preferences.accent
        table.enumerateAvailableRowViews { row, _ in
            (row as? FileSelectionRow)?.accent = accent
            row.needsDisplay = true
        }
    }
    @MainActor final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var parent: NativeFileTable
        var cachedItems: [FileItem] = []
        var syncing = false
        var cachedWidth: CGFloat = 0
        weak var table: NSTableView?
        init(_ parent: NativeFileTable) { self.parent = parent }
        func numberOfRows(in tableView: NSTableView) -> Int { cachedItems.count }
        func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
            let view = FileSelectionRow(); view.table = tableView; view.accent = parent.model.preferences.accent
            return view
        }
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard cachedItems.indices.contains(row), let key = tableColumn?.identifier else { return nil }
            let item = cachedItems[row]
            let cell = (tableView.makeView(withIdentifier: key, owner: self) as? NSTableCellView) ?? NSTableCellView()
            cell.identifier = key
            if cell.textField == nil {
                let text = NSTextField(labelWithString: ""); text.lineBreakMode = .byTruncatingMiddle
                text.font = .systemFont(ofSize: 13); text.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(text); cell.textField = text
                NSLayoutConstraint.activate([
                    text.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: key.rawValue == "name" ? 34 : 10),
                    text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
                    text.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                ])
                if key.rawValue == "name" {
                    let image = NSImageView(); image.translatesAutoresizingMaskIntoConstraints = false
                    cell.addSubview(image); cell.imageView = image
                    NSLayoutConstraint.activate([image.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10), image.centerYAnchor.constraint(equalTo: cell.centerYAnchor), image.widthAnchor.constraint(equalToConstant: 18), image.heightAnchor.constraint(equalToConstant: 18)])
                }
            }
            cell.textField?.textColor = key.rawValue == "name" ? .labelColor : .secondaryLabelColor
            switch key.rawValue {
            case "name":
                cell.textField?.stringValue = item.name
                cell.imageView?.image = NSWorkspace.shared.icon(for: item.isDirectory ? .folder : (UTType(item.typeIdentifier) ?? .data))
                cell.alphaValue = parent.model.cutURLs.contains(item.url) ? 0.48 : 1
            case "modified": cell.textField?.stringValue = item.modified.formatted(.dateTime.month(.twoDigits).day(.twoDigits).hour().minute())
            case "kind": cell.textField?.stringValue = item.kind
            case "size": cell.textField?.stringValue = item.isDirectory ? "—" : ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file)
            default: break
            }
            cell.toolTip = item.url.path
            return cell
        }
        func tableViewSelectionDidChange(_ notification: Notification) {
            guard !syncing, let table else { return }
            parent.selection = Set(table.selectedRowIndexes.compactMap { cachedItems.indices.contains($0) ? cachedItems[$0].url : nil })
            table.enumerateAvailableRowViews { row, _ in (row as? FileSelectionRow)?.updateTextColors(); row.needsDisplay = true }
        }
        func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
            guard let descriptor = tableView.sortDescriptors.first, let key = descriptor.key else { return }
            parent.session.sort = key; parent.session.ascending = descriptor.ascending
        }
        func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> (any NSPasteboardWriting)? { cachedItems.indices.contains(row) ? cachedItems[row].url as NSURL : nil }
        private func dropDestination(row: Int, operation: NSTableView.DropOperation) -> URL? {
            guard !parent.model.busy, !parent.session.loading, parent.session.archive == nil, !parent.session.isInTrash else { return nil }
            if operation == .on && cachedItems.indices.contains(row) { return cachedItems[row].directoryTarget }
            return parent.session.directory
        }
        func tableView(_ tableView: NSTableView, validateDrop info: any NSDraggingInfo, proposedRow row: Int, proposedDropOperation operation: NSTableView.DropOperation) -> NSDragOperation {
            guard info.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]),
                  dropDestination(row: row, operation: operation) != nil else { return [] }
            if operation == .on && cachedItems.indices.contains(row) { tableView.setDropRow(row, dropOperation: .on) }
            else { tableView.setDropRow(-1, dropOperation: .on) }
            return .copy
        }
        func tableView(_ tableView: NSTableView, acceptDrop info: any NSDraggingInfo, row: Int, dropOperation operation: NSTableView.DropOperation) -> Bool {
            guard let destination = dropDestination(row: row, operation: operation),
                  let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty else { return false }
            return parent.model.receiveDrop(urls.map { NSItemProvider(object: $0 as NSURL) }, to: destination) != nil
        }
        @objc func openItem() {
            guard let table, cachedItems.indices.contains(table.clickedRow) else { return }
            parent.model.rightActive = parent.isRight; parent.model.open(cachedItems[table.clickedRow])
        }
    }
}
