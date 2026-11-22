import Foundation

public struct TextSearchResult: Sendable {
    public struct Row: Identifiable, Sendable {
        public let id: Int
        public let range: NSRange
        public let line: Int
        public let column: Int
        public let preview: String
    }
    public let ranges: [NSRange]
    public let rows: [Row]
    public static let empty = Self(ranges: [], rows: [])
}
