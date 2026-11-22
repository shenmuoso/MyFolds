import AppKit
import UniformTypeIdentifiers

@MainActor enum ItemProviderURLs {
    static func load(_ providers: [NSItemProvider]) async -> [URL] {
        var urls: [URL] = []
        for provider in providers {
            let data: Data? = await withCheckedContinuation { continuation in
                provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in continuation.resume(returning: data) }
            }
            if let data, let url = URL(dataRepresentation: data, relativeTo: nil), url.isFileURL { urls.append(url) }
        }
        return urls
    }
}
