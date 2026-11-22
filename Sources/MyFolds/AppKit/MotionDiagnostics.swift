#if DEBUG
import Foundation

// Development-only, no screen capture or synthetic interaction. Samples are
// emitted by SwiftUI's animatable position setter during real user actions.
enum MotionDiagnostics {
    private static let queue = DispatchQueue(label: "com.myfolds.motion-diagnostics")
    static func record(position: Double, reduced: Bool) {
        let record = "{\"time\":\(Date().timeIntervalSince1970),\"position\":\(position),\"reduced\":\(reduced)}\n"
        queue.async {
            let url = URL(fileURLWithPath: "/tmp/MyFolds-motion-debug.jsonl")
            if !FileManager.default.fileExists(atPath: url.path) { FileManager.default.createFile(atPath: url.path, contents: nil) }
            guard let file = try? FileHandle(forWritingTo: url) else { return }
            defer { try? file.close() }
            do { try file.seekToEnd(); try file.write(contentsOf: Data(record.utf8)) } catch { }
        }
    }
}
#endif
