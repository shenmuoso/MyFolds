import SwiftUI
import UniformTypeIdentifiers
import MyFoldsCore

extension BrowserModel {
    @discardableResult
    func receiveDrop(_ providers: [NSItemProvider], to directory: URL) -> Task<Void, Never>? {
        guard !busy, !TrashLocation.contains(directory) else { return nil }
        return Task {
            let urls = await ItemProviderURLs.load(providers)
            let transferable = await DropPolicy.transferable(urls, to: directory)
            if !transferable.isEmpty { transfer(transferable, to: directory, move: false) }
        }
    }

    @discardableResult
    func receiveQuickAccessDrop(_ providers: [NSItemProvider]) -> Task<Void, Never> {
        Task {
            await quickAccess.add(ItemProviderURLs.load(providers))
            if let error = quickAccess.error { message = error }
        }
    }
}
