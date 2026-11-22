import Foundation

@MainActor
struct SidebarMenuCommand {
    let title: String
    let symbol: String?
    var enabled = true
    let action: () -> Void
    static var separator: Self { Self(title: "", symbol: nil, action: {}) }
}
