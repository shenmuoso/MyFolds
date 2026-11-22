import Foundation

public enum OpeningDestination: Equatable, Sendable {
    public static let builtInIdentifier = "myfolds://builtin"
    public static let systemIdentifier = "myfolds://system"
    case automatic, builtIn, system, application(String)

    public init(rule: String?) {
        switch rule {
        case Self.builtInIdentifier: self = .builtIn
        case Self.systemIdentifier: self = .system
        case .some(let path): self = .application(path)
        case nil: self = .automatic
        }
    }
}
