import Foundation

// Owns a cancellable subprocess; output is spooled to temporary files so a full
// pipe can never deadlock the reader or the UI executor.
private final class ProcessCancellation: @unchecked Sendable {
    let lock = NSLock()
    var process: Process?
    var cancelled = false
    func install(_ process: Process) throws {
        lock.lock(); defer { lock.unlock() }
        if cancelled { throw CancellationError() }
        self.process = process
        try process.run()
    }
    func cancel() {
        lock.lock(); defer { lock.unlock() }
        cancelled = true
        if let process, process.isRunning { process.terminate() }
    }
}

public enum CommandProcess {
    @concurrent public static func run(_ executable: String, arguments: [String], failureMessage: String = "磁盘映像命令未完成。") async throws -> Data {
        let state = ProcessCancellation()
        return try await withTaskCancellationHandler {
            let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: root) }
            let output = root.appendingPathComponent("output"), error = root.appendingPathComponent("error")
            FileManager.default.createFile(atPath: output.path, contents: nil)
            FileManager.default.createFile(atPath: error.path, contents: nil)
            let out = try FileHandle(forWritingTo: output), err = try FileHandle(forWritingTo: error)
            defer { try? out.close(); try? err.close() }
            let process = Process(); process.executableURL = URL(fileURLWithPath: executable); process.arguments = arguments
            process.standardOutput = out; process.standardError = err; process.standardInput = FileHandle.nullDevice
            try state.install(process)
            while process.isRunning { try await Task.sleep(for: .milliseconds(60)) }
            try Task.checkCancellation()
            guard process.terminationStatus == 0 else {
                let detail = (try? String(contentsOf: error, encoding: .utf8)) ?? ""
                throw FileOperationError.message(failureMessage + "\n" + detail.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return try Data(contentsOf: output)
        } onCancel: { state.cancel() }
    }
}
