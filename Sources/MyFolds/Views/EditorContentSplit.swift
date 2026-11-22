import SwiftUI

struct EditorContentSplit<Content: View>: View {
    @Bindable var search: EditorSearchModel
    @State private var resultsHeight: CGFloat = 175
    @ViewBuilder let content: Content
    var body: some View {
        GeometryReader { geometry in
            let maximum = max(80, geometry.size.height - 120)
            VStack(spacing: 0) {
                content.frame(maxWidth: .infinity, maxHeight: .infinity)
                if search.visible && search.showsResults {
                    EditorResultsDivider(height: $resultsHeight, maximum: maximum).frame(height: 7)
                    EditorSearchResults(search: search).frame(height: min(maximum, max(80, resultsHeight)))
                }
            }
        }
    }
}
