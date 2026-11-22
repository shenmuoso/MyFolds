import SwiftUI
import MyFoldsCore

struct SidebarLocation: View {
    let name: String
    let symbol: String
    let url: URL
    @Bindable var model: BrowserModel
    var volume: MountedVolume?
    var body: some View {
        SidebarAction(name, symbol: symbol, helpText: volume?.isDiskImage == true ? (volume?.imageURL?.path ?? "") + "\n挂载于 " + url.path : url.path,
                      selected: model.active.directory.standardizedFileURL.path == url.standardizedFileURL.path,
                      trailingAction: volume?.isDiskImage == true ? { if let volume { model.ejectImage(volume) } } : nil,
                      trailingBusy: volume.map { model.ejectingVolumes.contains($0.id) } ?? false) { model.go(url) }
            .onDrag { NSItemProvider(object: url as NSURL) }
            .sidebarContextMenu(SidebarLocationMenu(model: model, url: url, volume: volume))
    }
}
