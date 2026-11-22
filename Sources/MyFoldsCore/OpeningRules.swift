import Foundation

public enum OpeningRules {
    public static func normalizedExtension(_ input: String) -> String? {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.hasPrefix("*.") { value.removeFirst(2) }
        else if value.hasPrefix(".") { value.removeFirst() }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_+-"))
        guard !value.isEmpty, value.split(separator: ".", omittingEmptySubsequences: false).allSatisfy({ part in
            !part.isEmpty && part.unicodeScalars.allSatisfy { allowed.contains($0) }
        }) else { return nil }
        return value
    }
    public static func applicationPath(for url: URL, typeIdentifier: String, extensions: [String: String], types: [String: String], categories: [String: String]) -> String? {
        let suffix = matchingExtension(for: url, rules: extensions)
        if let suffix, let path = extensions[suffix] { return path }
        if let path = types[typeIdentifier] { return path }
        // Each category has its own default. An unset Markdown/HTML/image rule
        // must not silently inherit an external application from the text row.
        guard let category = OpeningCategory.matching(fileExtension: url.pathExtension, typeIdentifier: typeIdentifier).first else { return nil }
        return categories[category.rawValue]
    }
    public static func matchingExtension(for url: URL, rules: [String: String]) -> String? {
        let name = url.lastPathComponent.lowercased()
        return rules.keys.filter { name.hasSuffix("." + $0) }.max { $0.count < $1.count }
    }
}
