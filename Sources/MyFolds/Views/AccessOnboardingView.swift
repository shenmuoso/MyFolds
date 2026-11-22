import SwiftUI

struct AccessOnboardingView: View {
    @Bindable var access: FileAccessManager
    let finish: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                Image(AppIconProvider.assetName, bundle: .main).resizable().frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text("让 MyFolds 访问你的文件").font(.title2.weight(.semibold))
                    Text("一次设置，开始浏览。").foregroundStyle(.secondary)
                }
            }
            AccessSettings(access: access)
            HStack {
                Text("访问权限由 macOS 管理，可随时在系统设置中撤销。")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Button("开始使用", action: finish).keyboardShortcut(.defaultAction)
            }
        }.padding(28).frame(width: 550).fixedSize(horizontal: false, vertical: true)
            .modifier(AppIconAppearance())
    }
}
