import Foundation
import CryptoKit

public struct TextFileSnapshot: Sendable {
    public let text: String
    public let encoding: TextFileEncoding
    public let revision: Data
}

public enum TextFileEncoding: Sendable {
    case utf8, utf8BOM, utf16LE, utf16BE
    public var label: String {
        switch self { case .utf8: "UTF-8"; case .utf8BOM: "UTF-8 BOM"; case .utf16LE: "UTF-16 LE"; case .utf16BE: "UTF-16 BE" }
    }
    var foundation: String.Encoding {
        switch self { case .utf8, .utf8BOM: .utf8; case .utf16LE: .utf16LittleEndian; case .utf16BE: .utf16BigEndian }
    }
    var prefix: Data {
        switch self { case .utf8: Data(); case .utf8BOM: Data([0xef, 0xbb, 0xbf]); case .utf16LE: Data([0xff, 0xfe]); case .utf16BE: Data([0xfe, 0xff]) }
    }
}

public enum TextDocumentError: LocalizedError {
    case tooLarge, unsupportedEncoding, binary, changedOnDisk
    public var errorDescription: String? {
        switch self {
        case .tooLarge: "内置编辑器支持不超过 8 MB 的文本。请使用其他应用打开此文件。"
        case .unsupportedEncoding: "暂不支持此文本编码。内置编辑器支持 UTF-8 和带 BOM 的 UTF-16，请使用其他应用打开。"
        case .binary: "这个文件包含二进制内容，不能作为文本安全编辑。"
        case .changedOnDisk: "文件已被其他应用修改，尚未覆盖。请重新载入，或将编辑内容另存为新文件。"
        }
    }
}

public actor TextDocumentStore {
    public init() {}
    public func read(_ url: URL) throws -> TextFileSnapshot {
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= 8 * 1024 * 1024 else { throw TextDocumentError.tooLarge }
        let data = try Data(contentsOf: url)
        guard data.count <= 8 * 1024 * 1024 else { throw TextDocumentError.tooLarge }
        let encoding: TextFileEncoding
        if data.starts(with: [0xef, 0xbb, 0xbf]) { encoding = .utf8BOM }
        else if data.starts(with: [0xff, 0xfe]) { encoding = .utf16LE }
        else if data.starts(with: [0xfe, 0xff]) { encoding = .utf16BE }
        else { encoding = .utf8 }
        guard let text = String(data: data.dropFirst(encoding.prefix.count), encoding: encoding.foundation) else { throw TextDocumentError.unsupportedEncoding }
        guard !text.unicodeScalars.contains(where: { $0.value == 0 || ($0.value < 9) || (14...31).contains($0.value) }) else { throw TextDocumentError.binary }
        return TextFileSnapshot(text: text, encoding: encoding, revision: Data(SHA256.hash(data: data)))
    }
    public func save(_ text: String, to url: URL, encoding: TextFileEncoding, expectedRevision: Data?) throws -> Data {
        let destination = url.resolvingSymlinksInPath()
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var result: Result<Data, Error>?
        // Coordinate with document-based apps and check the revision inside the
        // coordinated write. A conflict never silently overwrites external work.
        coordinator.coordinate(writingItemAt: destination, options: .forReplacing, error: &coordinationError) { target in
            result = Result {
                if let expectedRevision {
                    let current = try Data(contentsOf: target)
                    guard Data(SHA256.hash(data: current)) == expectedRevision else { throw TextDocumentError.changedOnDisk }
                }
                guard let body = text.data(using: encoding.foundation) else { throw TextDocumentError.unsupportedEncoding }
                let bytes = encoding.prefix + body
                try bytes.write(to: target, options: .atomic)
                return Data(SHA256.hash(data: bytes))
            }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw CocoaError(.fileWriteUnknown) }
        return try result.get()
    }
}
