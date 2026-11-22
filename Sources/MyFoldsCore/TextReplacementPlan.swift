import Foundation

public struct TextReplacementPlan: Sendable {
    public let range: NSRange
    public let replacement: String
    public let count: Int
}
