import Foundation

enum AppInformation {
    static let author = "shenmuoso"
    static let authorURL = URL(string: "https://github.com/shenmuoso")!
    static let projectURL = URL(string: "https://github.com/shenmuoso/MyFolds")!
    static let recommendedProjectURL = URL(string: "https://github.com/shenmuoso/mac-scope")!

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "开发版"
    }
    static var versionLabel: String {
        guard let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else { return version }
        return "\(version)（\(build)）"
    }
}
