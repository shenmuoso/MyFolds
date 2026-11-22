import Foundation

struct QuickAccessEntry: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var path: String
    var name: String
    var isDirectory: Bool
    var bookmark: Data?
    var url: URL { URL(fileURLWithPath: path) }
}
