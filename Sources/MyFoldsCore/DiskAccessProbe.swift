import Foundation
import Darwin

public enum DiskAccessStatus: Sendable { case unknown, restricted, available }

public enum DiskAccessProbe {
    // macOS exposes no public FDA-status API. Test access to the protected TCC
    // file without reading any bytes or modifying it. Missing/other failures
    // remain unknown; onboarding completion never implies authorization.
    @concurrent public static func check() async -> DiskAccessStatus {
        let paths = [URL.homeDirectory.appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db").path,
                     "/Library/Application Support/com.apple.TCC/TCC.db"]
        for path in paths {
            let descriptor = Darwin.open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)
            if descriptor >= 0 { Darwin.close(descriptor); return .available }
            if errno == EPERM || errno == EACCES { return .restricted }
        }
        return .unknown
    }
}
