import AppKit
import MyFoldsCore

enum SyntaxPalette {
    static func color(_ kind: SyntaxToken.Kind, dark: Bool) -> NSColor {
        let hex: UInt32
        switch kind {
        case .addition: hex = dark ? 0x9bd89c : 0x226536
        case .deletion, .error: hex = dark ? 0xffa5a5 : 0xa22c35
        case .warning: hex = dark ? 0xf0cc83 : 0x805000
        case .keyword: hex = dark ? 0xff8abc : 0x832397
        case .string: hex = dark ? 0xffb18a : 0x9b3020
        case .number: hex = dark ? 0xe9ca80 : 0x805000
        case .comment: hex = dark ? 0xa5afbb : 0x52616a
        case .type: hex = dark ? 0x80d4cb : 0x005f68
        case .function: hex = dark ? 0xaabfff : 0x2655a2
        case .property: hex = dark ? 0xd8b2ef : 0x6b3e7d
        case .tag: hex = dark ? 0xf899ba : 0x8c244a
        case .heading: hex = dark ? 0xe4baff : 0x6e2a91
        case .link: hex = dark ? 0x8bc4ff : 0x1256a0
        case .code: hex = dark ? 0xc3d7ac : 0x3c662a
        }
        return NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}
