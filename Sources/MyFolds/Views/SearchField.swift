import SwiftUI

struct SearchField: View {
    @Bindable var model: BrowserModel
    @FocusState private var focused: Bool
    var body: some View {
        @Bindable var session = model.active
        HStack(spacing: 5) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("搜索此文件夹", text: $session.query).textFieldStyle(.plain).focused($focused)
            if !model.active.query.isEmpty {
                Button("清除搜索", systemImage: "xmark.circle.fill") { model.active.query = "" }.buttonStyle(.plain).labelStyle(.iconOnly)
            }
        }.font(.system(size: 12)).padding(.horizontal, 12).frame(height: 35).glassEffect(.regular, in: .capsule)
            .onChange(of: model.searchFocused) { if model.searchFocused { focused = true; model.searchFocused = false } }
    }
}
