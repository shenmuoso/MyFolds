import Foundation
import CryptoKit

public actor FileOperations {
    private let fm = FileManager.default
    public init() {}

    public static func uniqueURL(_ proposed: URL) -> URL {
        let fm = FileManager.default
        if !fm.fileExists(atPath: proposed.path) { return proposed }
        let ext = proposed.pathExtension
        let stem = ext.isEmpty ? proposed.lastPathComponent : proposed.deletingPathExtension().lastPathComponent
        var index = 2
        while true {
            let name = "\(stem) \(index)" + (ext.isEmpty ? "" : ".\(ext)")
            let candidate = proposed.deletingLastPathComponent().appending(path: name)
            if !fm.fileExists(atPath: candidate.path) { return candidate }
            index += 1
        }
    }

    public static func validateName(_ name: String) throws {
        guard !name.isEmpty, name != ".", name != "..", !name.contains("/"), !name.contains(":"), !name.contains("\0") else {
            throw FileOperationError.message("名称不能为空，也不能包含 /、: 或空字符。")
        }
    }

    public func transfer(_ sources: [URL], to folder: URL, move: Bool,
                         conflict: @Sendable (URL, URL, Bool) async -> ConflictDecision,
                         progress: @Sendable (String, Int, Int) async -> Void) async -> OperationResult {
        var result = OperationResult()
        let targetRoot = folder.resolvingSymlinksInPath().standardizedFileURL
        for (index, source) in sources.enumerated() {
            var stage: URL?
            var backup: URL?
            var installedDestination: URL?
            do {
                try Task.checkCancellation()
                await progress(source.lastPathComponent, index, sources.count)
                let canonical = source.resolvingSymlinksInPath().standardizedFileURL
                let values = try source.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                if values.isDirectory == true && values.isSymbolicLink != true && (targetRoot == canonical || targetRoot.path.hasPrefix(canonical.path + "/")) {
                    throw FileOperationError.message("不能把文件夹放进自身或其子文件夹。")
                }
                var destination = folder.appending(path: source.lastPathComponent)
                if source.standardizedFileURL == destination.standardizedFileURL && move { result.skipped += 1; continue }
                if fm.fileExists(atPath: destination.path) {
                    let decision = await conflict(source, destination, values.isDirectory == true)
                    switch decision {
                    case .cancel: throw CancellationError()
                    case .skip: result.skipped += 1; continue
                    case .keepBoth: destination = Self.uniqueURL(destination)
                    case .replace:
                        guard source.standardizedFileURL != destination.standardizedFileURL else { throw FileOperationError.message("不能用文件替换自身，请选择保留两份。") }
                        guard values.isDirectory != true, (try destination.resourceValues(forKeys: [.isDirectoryKey])).isDirectory != true else { throw FileOperationError.message("文件夹同名请使用保留两份或跳过。") }
                        // Keep the previous destination recoverable, even if installation fails.
                        backup = folder.appending(path: ".myfolds-backup-" + UUID().uuidString)
                    }
                }
                let staging = folder.appending(path: ".myfolds-partial-" + UUID().uuidString)
                stage = staging
                try await copyTree(source, to: staging)
                try Task.checkCancellation()
                if let backup { try fm.moveItem(at: destination, to: backup) }
                do { try fm.moveItem(at: staging, to: destination) }
                catch {
                    if let backup { try? fm.moveItem(at: backup, to: destination) }
                    throw error
                }
                stage = nil
                installedDestination = destination
                let receipt = try OperationReceipt(kind: move ? .move : .copy, source: move ? source : nil, destination: destination, backup: backup)
                if move {
                    // Source is removed only after the complete staged copy is verified and installed.
                    try fm.removeItem(at: source)
                }
                result.receipts.append(receipt)
                installedDestination = nil
                await progress(source.lastPathComponent, index + 1, sources.count)
            } catch is CancellationError {
                if let stage { try? fm.removeItem(at: stage) }
                result.cancelled = true
                break
            } catch {
                if let stage { try? fm.removeItem(at: stage) }
                if let installedDestination {
                    result.failures.append("\(source.lastPathComponent)：目标副本已保留在 \(installedDestination.path)，源文件未能完整移除。\(error.localizedDescription)")
                } else {
                    result.failures.append("\(source.lastPathComponent)：\(error.localizedDescription)")
                }
            }
        }
        return result
    }

    private func copyTree(_ source: URL, to target: URL) async throws {
        try Task.checkCancellation()
        let values = try source.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey])
        if values.isSymbolicLink == true {
            try fm.createSymbolicLink(atPath: target.path, withDestinationPath: fm.destinationOfSymbolicLink(atPath: source.path))
        } else if values.isDirectory == true {
            try fm.createDirectory(at: target, withIntermediateDirectories: false)
            let children = try fm.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
            for child in children { try await copyTree(child, to: target.appending(path: child.lastPathComponent)) }
            let after = try fm.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
            guard Set(children) == Set(after), try source.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate == values.contentModificationDate else {
                throw FileOperationError.message("复制期间目录发生变化，请重试。")
            }
        } else {
            // Native copy preserves resource forks and extended attributes. Verification is cancellable.
            try fm.copyItem(at: source, to: target)
            try Task.checkCancellation()
            guard try digest(source) == digest(target) else { throw FileOperationError.message("副本校验失败，源文件已保留。") }
            let after = try source.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            guard after.fileSize == values.fileSize, after.contentModificationDate == values.contentModificationDate else {
                throw FileOperationError.message("复制期间文件发生变化，请重试。")
            }
        }
        if values.isSymbolicLink != true, let date = values.contentModificationDate { try fm.setAttributes([.modificationDate: date], ofItemAtPath: target.path) }
    }

    private func digest(_ url: URL) throws -> SHA256.Digest {
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        var hash = SHA256()
        while let data = try file.read(upToCount: 1_048_576), !data.isEmpty { try Task.checkCancellation(); hash.update(data: data) }
        return hash.finalize()
    }

    public func createFolder(in directory: URL, name: String) throws -> OperationReceipt {
        try Self.validateName(name)
        let url = directory.appending(path: name)
        try fm.createDirectory(at: url, withIntermediateDirectories: false)
        return try OperationReceipt(kind: .create, source: nil, destination: url)
    }
    public func rename(_ source: URL, to name: String) throws -> OperationReceipt {
        try Self.validateName(name)
        let target = source.deletingLastPathComponent().appending(path: name)
        guard source != target else { throw FileOperationError.message("名称没有改变。") }
        try fm.moveItem(at: source, to: target)
        return try OperationReceipt(kind: .move, source: source, destination: target)
    }
    public func trash(_ urls: [URL]) -> OperationResult {
        var result = OperationResult()
        for url in urls {
            do {
                try Task.checkCancellation()
                var destination: NSURL?
                try fm.trashItem(at: url, resultingItemURL: &destination)
                if let destination { result.receipts.append(try OperationReceipt(kind: .trash, source: url, destination: destination as URL)) }
            } catch is CancellationError { result.cancelled = true; break }
            catch { result.failures.append("\(url.lastPathComponent)：\(error.localizedDescription)") }
        }
        return result
    }
    public func undo(_ receipts: [OperationReceipt]) throws {
        // Preflight the full batch before moving anything.
        for receipt in receipts {
            guard try OperationReceipt.fingerprint(receipt.destination) == receipt.fingerprint else { throw FileOperationError.message("\(receipt.destination.lastPathComponent) 已被修改，无法安全撤销。") }
            if let source = receipt.source, fm.fileExists(atPath: source.path) { throw FileOperationError.message("原位置已被占用：\(source.path)") }
        }
        for receipt in receipts.reversed() {
            if let source = receipt.source { try fm.moveItem(at: receipt.destination, to: source) }
            else { try fm.trashItem(at: receipt.destination, resultingItemURL: nil) }
            if let backup = receipt.backup { try fm.moveItem(at: backup, to: receipt.destination) }
        }
    }
}
