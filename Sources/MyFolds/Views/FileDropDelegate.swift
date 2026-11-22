import SwiftUI
import UniformTypeIdentifiers

struct FileDropDelegate: DropDelegate {
    let model: BrowserModel
    let directory: URL?
    var enabled = true
    @Binding var targeted: Bool
    func validateDrop(info: DropInfo) -> Bool {
        enabled && !model.busy && directory != nil && info.hasItemsConforming(to: [UTType.fileURL])
    }
    func dropEntered(info: DropInfo) { targeted = validateDrop(info: info) }
    func dropExited(info: DropInfo) { targeted = false }
    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: validateDrop(info: info) ? .copy : .cancel) }
    func performDrop(info: DropInfo) -> Bool {
        targeted = false
        guard validateDrop(info: info), let directory else { return false }
        return model.receiveDrop(info.itemProviders(for: [UTType.fileURL]), to: directory) != nil
    }
}
