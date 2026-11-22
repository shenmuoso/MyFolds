import Foundation

public struct TextSearchOptions: Equatable, Sendable {
    public enum Mode: String, CaseIterable, Identifiable, Sendable {
        case normal, extended, regularExpression
        public var id: Self { self }
        public var title: String {
            switch self { case .normal: "普通文本"; case .extended: "转义字符"; case .regularExpression: "正则表达式" }
        }
    }
    public var mode: Mode = .normal
    public var caseSensitive = false
    public var wholeWord = false
    public var dotMatchesNewline = false
    public init() {}
}
