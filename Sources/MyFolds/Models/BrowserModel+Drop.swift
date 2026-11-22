import SwiftUI
import UniformTypeIdentifiers
import MyFoldsCore

extension BrowserModel {
    @discardableResult
    func receiveDrop(_ providers: [NSItemProvider], to directory: URL) -> Task<Void, Never>? {
        guard !busy, !TrashLocation.contains(directory) else { return nil }
        return Task {
            let urls = await ItemProviderURLs.load(providers)
            do {
                guard let destination = try await directoryService.item(at: directory).directoryTarget,
                      !TrashLocation.contains(destination) else { return }
                let transferable = await DropPolicy.transferable(urls, to: destination)
                if !transferable.isEmpty { transfer(transferable, to: destination, move: false) }
            } catch { message = "无法访问目标文件夹：" + error.localizedDescription }
        }
    }

    @discardableResult
    func receiveDrop(_ providers: [NSItemProvider], to session: FolderSession) -> Task<Void, Never>? {
        guard session.archive == nil, !session.loading, !session.isInTrash else { return nil }
        return receiveDrop(providers, to: session.directory)
    }

    @discardableResult
    func receiveQuickAccessDrop(_ providers: [NSItemProvider]) -> Task<Void, Never> {
        Task {
            await quickAccess.add(ItemProviderURLs.load(providers))
            if let error = quickAccess.error { message = error }
        }
    }
}
