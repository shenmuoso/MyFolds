import Foundation

public struct SyntaxToken: Equatable, Sendable {
    public enum Kind: String, Sendable { case keyword, string, number, comment, type, function, property, tag, heading, link, code, addition, deletion, warning, error }
    public let range: NSRange
    public let kind: Kind
    public init(range: NSRange, kind: Kind) { self.range = range; self.kind = kind }
}
