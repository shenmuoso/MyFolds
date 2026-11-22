import Foundation
import MyFoldsCore

@MainActor @Observable
final class PreviewModel {
    let items: [FileItem]
    var index: Int
    var actualSize = false
    var item: FileItem { items[index] }
    init(items: [FileItem], index: Int) { self.items = items; self.index = index }
    func next(_ delta: Int) { index = min(items.count - 1, max(0, index + delta)); actualSize = false }
}
