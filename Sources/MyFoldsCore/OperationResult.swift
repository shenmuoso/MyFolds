import Foundation

public struct OperationResult: Sendable {
    public var receipts: [OperationReceipt] = []
    public var failures: [String] = []
    public var skipped: Int = 0
    public var cancelled = false
    public init() {}
}
