import Foundation
import CArchive

public actor ArchiveService {
    public init() {}
    private func message(_ archive: OpaquePointer?) -> FileOperationError {
        let reason = archive_error_string(archive).map { String(cString: $0) } ?? "无法读取压缩包"
        return .message("压缩操作失败：\(reason)。加密或分卷内容可能需要其他解压应用。")
    }
    private func open(_ url: URL) throws -> OpaquePointer {
        guard let reader = archive_read_new() else { throw FileOperationError.message("无法创建解压任务。") }
        archive_read_support_filter_all(reader)
        archive_read_support_format_all(reader)
        if ["gz", "bz2", "xz"].contains(url.pathExtension.lowercased()) { archive_read_support_format_raw(reader) }
        if archive_read_open_filename(reader, url.path, 65_536) != ARCHIVE_OK {
            let error = message(reader); archive_read_free(reader); throw error
        }
        return reader
    }
    public static func safePath(_ raw: String) throws -> String {
        guard !raw.hasPrefix("/"), !raw.hasPrefix("\\"), !raw.contains("\0"), !raw.contains("\\") else { throw FileOperationError.message("压缩包包含不安全路径：\(raw)") }
        let components = raw.split(separator: "/").filter { $0 != "." }
        guard !components.contains(".."), !(components.first.map { $0.contains(":") } ?? false) else { throw FileOperationError.message("压缩包包含越界路径：\(raw)") }
        return components.joined(separator: "/")
    }
    private func path(_ entry: OpaquePointer, reader: OpaquePointer, source: URL) throws -> String {
        if archive_format(reader) == ARCHIVE_FORMAT_RAW { return try Self.safePath(source.deletingPathExtension().lastPathComponent) }
        guard let raw = archive_entry_pathname_utf8(entry) ?? archive_entry_pathname(entry) else { throw FileOperationError.message("压缩包内有无法识别的文件名。") }
        return try Self.safePath(String(cString: raw))
    }
    public func list(_ url: URL) throws -> [ArchiveItem] {
        let reader = try open(url); defer { archive_read_free(reader) }
        var entries: [ArchiveItem] = []
        var entry: OpaquePointer?
        while true {
            try Task.checkCancellation()
            let code = archive_read_next_header(reader, &entry)
            if code == ARCHIVE_EOF { break }
            guard code >= ARCHIVE_WARN, let entry else { throw message(reader) }
            let name = try path(entry, reader: reader, source: url)
            if !name.isEmpty {
                entries.append(ArchiveItem(path: name, size: archive_entry_size(entry), isDirectory: archive_entry_filetype(entry) == 0o040000, isLink: archive_entry_symlink(entry) != nil || archive_entry_hardlink(entry) != nil))
            }
            guard entries.count <= 100_000 else { throw FileOperationError.message("此压缩包条目超过测试版上限（100,000 项）。") }
            guard archive_read_data_skip(reader) >= ARCHIVE_WARN else { throw message(reader) }
        }
        return entries
    }
    public func extract(_ url: URL, selected: Set<String>, to folder: URL,
                        progress: @Sendable (String) async -> Void) async throws -> URL {
        let fm = FileManager.default
        let stage = folder.appending(path: ".myfolds-extract-" + UUID().uuidString)
        try fm.createDirectory(at: stage, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        var installed = false
        defer { if !installed { try? fm.removeItem(at: stage) } }
        let reader = try open(url); defer { archive_read_free(reader) }
        var entry: OpaquePointer?
        var buffer = [UInt8](repeating: 0, count: 1_048_576)
        var seen = Set<String>()
        while true {
            try Task.checkCancellation()
            let code = archive_read_next_header(reader, &entry)
            if code == ARCHIVE_EOF { break }
            guard code >= ARCHIVE_WARN, let entry else { throw message(reader) }
            let relative = try path(entry, reader: reader, source: url)
            if relative.isEmpty { continue }
            guard selected.isEmpty || selected.contains(where: { relative == $0 || relative.hasPrefix($0 + "/") }) else {
                guard archive_read_data_skip(reader) >= ARCHIVE_WARN else { throw message(reader) }; continue
            }
            guard archive_entry_symlink(entry) == nil, archive_entry_hardlink(entry) == nil else { throw FileOperationError.message("测试版不提取压缩包中的链接：\(relative)。原包未改动。") }
            let type = archive_entry_filetype(entry)
            guard type == 0o040000 || type == 0o100000 else { throw FileOperationError.message("不支持的压缩条目类型：\(relative)") }
            let output = stage.appending(path: relative)
            await progress(relative)
            if type == 0o040000 { try fm.createDirectory(at: output, withIntermediateDirectories: true) }
            else {
                guard seen.insert(relative).inserted, !fm.fileExists(atPath: output.path) else { throw FileOperationError.message("压缩包包含重复的输出路径：\(relative)") }
                try fm.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
                guard fm.createFile(atPath: output.path, contents: nil) else { throw FileOperationError.message("无法写入：\(relative)") }
                let handle = try FileHandle(forWritingTo: output)
                do {
                    while true {
                        try Task.checkCancellation()
                        let size = archive_read_data(reader, &buffer, buffer.count)
                        if size == 0 { break }
                        guard size > 0 else { throw message(reader) }
                        try handle.write(contentsOf: buffer.prefix(size))
                    }
                    try handle.close()
                } catch { try? handle.close(); throw error }
            }
        }
        let target = FileOperations.uniqueURL(folder.appending(path: url.deletingPathExtension().lastPathComponent + " 解压"))
        try fm.moveItem(at: stage, to: target)
        installed = true
        return target
    }

    public func createZIP(_ urls: [URL], at output: URL) throws {
        guard !FileManager.default.fileExists(atPath: output.path) else { throw FileOperationError.message("目标 ZIP 已存在，请选择其他名称。") }
        let stage = output.deletingLastPathComponent().appending(path: ".myfolds-zip-" + UUID().uuidString)
        var completed = false
        defer { if !completed { try? FileManager.default.removeItem(at: stage) } }
        guard let writer = archive_write_new() else { throw FileOperationError.message("无法创建 ZIP。") }
        defer { archive_write_free(writer) }
        guard archive_write_set_format_zip(writer) == ARCHIVE_OK, archive_write_open_filename(writer, stage.path) == ARCHIVE_OK else { throw message(writer) }
        var roots = Set<String>()
        for url in urls {
            guard roots.insert(url.lastPathComponent).inserted else { throw FileOperationError.message("选择的文件有重复名称，请分别压缩。") }
            try appendZIP(url, name: url.lastPathComponent, writer: writer)
        }
        guard archive_write_close(writer) == ARCHIVE_OK else { throw message(writer) }
        try FileManager.default.moveItem(at: stage, to: output)
        completed = true
    }
    private func appendZIP(_ url: URL, name: String, writer: OpaquePointer) throws {
        try Task.checkCancellation()
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey])
        guard values.isSymbolicLink != true else { throw FileOperationError.message("测试版 ZIP 创建不包含符号链接：\(name)") }
        guard let entry = archive_entry_new() else { throw FileOperationError.message("无法创建压缩条目。") }
        defer { archive_entry_free(entry) }
        let directory = values.isDirectory == true
        archive_entry_set_pathname(entry, name)
        archive_entry_set_filetype(entry, directory ? 0o040000 : 0o100000)
        archive_entry_set_perm(entry, directory ? 0o755 : 0o644)
        archive_entry_set_size(entry, directory ? 0 : Int64(values.fileSize ?? 0))
        archive_entry_set_mtime(entry, Int(values.contentModificationDate?.timeIntervalSince1970 ?? 0), 0)
        guard archive_write_header(writer, entry) == ARCHIVE_OK else { throw message(writer) }
        if directory {
            for child in try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) { try appendZIP(child, name: name + "/" + child.lastPathComponent, writer: writer) }
        } else {
            let file = try FileHandle(forReadingFrom: url); defer { try? file.close() }
            while let data = try file.read(upToCount: 1_048_576), !data.isEmpty {
                try Task.checkCancellation()
                let count = data.withUnsafeBytes { archive_write_data(writer, $0.baseAddress, data.count) }
                guard count == data.count else { throw message(writer) }
            }
        }
        guard archive_write_finish_entry(writer) == ARCHIVE_OK else { throw message(writer) }
    }
}
