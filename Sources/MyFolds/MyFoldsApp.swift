import SwiftUI

@main
struct MyFoldsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model: BrowserModel
    init() {
        let browser = BrowserModel()
        _model = State(initialValue: browser)
        AppDelegate.browser = browser
    }
    var body: some Scene {
        Window("MyFolds", id: "main") {
            WindowMaterial(preferences: model.preferences) {
                BrowserView(model: model).browserMotionPreference(model.preferences)
                    .modifier(AppIconAppearance())
            }
            .frame(minWidth: 920, minHeight: 600)
            .ignoresSafeArea()
            .containerBackground(.clear, for: .window)
        }
        .defaultSize(width: 1200, height: 760)
        .windowStyle(.hiddenTitleBar)
        .commands {
            FileCommands(model: model)
            CommandGroup(replacing: .appInfo) {
                Button("关于 MyFolds", action: AppDelegate.showAbout)
            }
        }
    }
}
