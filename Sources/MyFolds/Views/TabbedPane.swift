import SwiftUI

struct TabbedPane: View {
    @Bindable var model: BrowserModel
    let isRight: Bool
    @Environment(\.myfoldsReduceMotion) private var reduced
    private var session: FolderSession { isRight ? model.right : model.primary }
    var body: some View {
        VStack(spacing: 0) {
            TabStrip(model: model, isRight: isRight)
            FolderPane(session: session, model: model, isRight: isRight)
                .id(session.id).transition(.opacity)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(BrowserMotion.content(reduced), value: session.id)
    }
}
