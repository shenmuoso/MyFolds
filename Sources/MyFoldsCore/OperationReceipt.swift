import Foundation
import CryptoKit

public struct OperationReceipt: Sendable {
    public enum Kind: Sendable { case copy, move, create, trash }
    public let kind: Kind
    public let source: URL?
    public let destination: URL
    public let backup: URL?
    public let fingerprint: String
    public init(kind: Kind, source: URL?, destination: URL, backup: URL? = nil) throws {
        self.kind = kind; self.source = source; self.destination = destination; self.backup = backup
        fingerprint = try Self.fingerprint(destination)
    }
    public static func fingerprint(_ url: URL) throws -> String {
        let fm = FileManager.default
        let attributes = try fm.attributesOfItem(atPath: url.path)
        let type = attributes[.type] as? FileAttributeType
        let date = (attributes[.modificationDate] as? Date)?.timeIntervalSinceReferenceDate ?? 0
        var hash = SHA256()
        hash.update(data: Data("\(attributes[.systemFileNumber] ?? "")/\(attributes[.size] ?? "")/\(date)/\(type?.rawValue ?? "")".utf8))
        if type == .typeSymbolicLink {
            hash.update(data: Data(try fm.destinationOfSymbolicLink(atPath: url.path).utf8))
        } else if type == .typeDirectory {
            for child in try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                hash.update(data: Data((child.lastPathComponent + "\0" + (try fingerprint(child))).utf8))
            }
        } else if type == .typeRegular {
            let file = try FileHandle(forReadingFrom: url); defer { try? file.close() }
            while let data = try file.read(upToCount: 1_048_576), !data.isEmpty { hash.update(data: data) }
        }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
