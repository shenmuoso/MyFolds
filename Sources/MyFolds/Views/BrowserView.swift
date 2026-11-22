import SwiftUI

struct BrowserView: View {
    @Bindable var model: BrowserModel
    @Environment(\.myfoldsReduceMotion) private var reduced
    var body: some View {
        HStack(spacing: 0) {
            if model.sidebarVisible {
                BrowserSidebar(model: model).frame(width: 194)
                    .transition(BrowserMotion.insertion(reduced, edge: .leading))
            }
            VStack(spacing: 0) {
                BrowserToolbar(model: model)
                HStack(spacing: 0) {
                    TabbedPane(model: model, isRight: false)
                    if model.split {
                        Divider().opacity(0.25)
                        TabbedPane(model: model, isRight: true).transition(BrowserMotion.insertion(reduced))
                    } else if model.inspector { InspectorView(model: model).frame(width: 260).transition(BrowserMotion.insertion(reduced)) }
                }
                if model.busy || !model.cutURLs.isEmpty { OperationBar(model: model).transition(.opacity) }
            }
        }
        .animation(reduced ? nil : BrowserMotion.layout(false), value: model.split)
        .animation(reduced ? nil : BrowserMotion.layout(false), value: model.sidebarVisible)
        .animation(reduced ? nil : BrowserMotion.layout(false), value: model.inspector)
        .animation(BrowserMotion.feedback(reduced), value: model.busy)
        .appAccentPreference(model.preferences)
        .ignoresSafeArea()
        .task { await model.start() }
        .onChange(of: model.primary.directory) { model.saveSession() }
        .onChange(of: model.right.directory) { model.saveSession() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await model.access.refreshDiskAccess() }
            model.refreshVolumes()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didMountNotification)) { _ in model.refreshVolumes() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didUnmountNotification)) { _ in model.refreshVolumes() }
        .onChange(of: model.preferences.showHidden) { model.refreshAll() }
        .alert("MyFolds", isPresented: Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })) {
            Button("好", role: .cancel) { model.message = nil }
        } message: { Text(model.message ?? "") }
        .sheet(isPresented: $model.showsTasks) { TaskHistoryView(model: model) }
        .sheet(isPresented: $model.showsAccessOnboarding) { AccessOnboardingView(access: model.access) { model.finishAccessOnboarding() } }
    }
}
