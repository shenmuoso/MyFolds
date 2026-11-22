import Foundation

public struct TextLineIndex: Sendable {
    public let starts: [Int]
    public init() { starts = [0] }
    public init(_ text: String) throws {
        var offsets = [0], previous: UInt16 = 0
        for (offset, unit) in text.utf16.enumerated() {
            if offset % 8192 == 0 { try Task.checkCancellation() }
            if unit == 10, previous == 13 { offsets[offsets.count - 1] = offset + 1 }
            else if unit == 10 || unit == 13 || unit == 0x2028 || unit == 0x2029 || unit == 0x85 { offsets.append(offset + 1) }
            previous = unit
        }
        starts = offsets
    }
    public func line(at offset: Int) -> Int {
        var low = 0, high = starts.count
        while low < high {
            let middle = (low + high) / 2
            if starts[middle] <= offset { low = middle + 1 } else { high = middle }
        }
        return max(0, low - 1)
    }
}
