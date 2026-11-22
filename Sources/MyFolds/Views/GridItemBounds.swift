import SwiftUI

struct GridItemBounds: PreferenceKey {
    static var defaultValue: [URL: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [URL: Anchor<CGRect>], nextValue: () -> [URL: Anchor<CGRect>]) { value.merge(nextValue(), uniquingKeysWith: { _, new in new }) }
}
