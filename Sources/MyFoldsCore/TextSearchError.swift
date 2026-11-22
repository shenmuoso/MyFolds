import Foundation

public enum TextSearchError: LocalizedError {
    case invalidPattern(String), invalidEscape, invalidCapture(Int), invalidRange, tooManyMatches, timedOut, tooLarge
    public var errorDescription: String? {
        switch self {
        case .invalidPattern(let reason): "正则表达式无效：\(reason)"
        case .invalidEscape: "转义字符不完整。支持 \\n、\\r、\\t 和 \\\\。"
        case .invalidCapture(let number): "替换内容引用了不存在的捕获组 \(number)。"
        case .invalidRange: "文本或选区已变化，请重新查找。"
        case .tooManyMatches: "匹配超过 100,000 处，请缩小搜索范围。尚未替换任何内容。"
        case .timedOut: "搜索耗时过长，请简化正则表达式或缩小选区。"
        case .tooLarge: "替换后的文本将超过编辑器的 8 MB 限制，尚未修改内容。"
        }
    }
}
