import SwiftUI

struct AccessOnboardingView: View {
    @Bindable var access: FileAccessManager
    let finish: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                Image(AppIconProvider.assetName, bundle: .main).resizable().frame(width: 48, height: 48)
                Text("开启完全磁盘访问").font(.system(size: 19, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("系统设置 → 隐私与安全性 → 完全磁盘访问权限")
                    .font(.system(size: 12, weight: .medium))
                Text("打开 MyFolds 的开关；若未列出，点击 ＋ 添加应用。\n开启后可能需要重新打开 MyFolds。")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }.fixedSize(horizontal: false, vertical: true)
            Toggle("下次不再提醒", isOn: $access.suppressDiskAccessReminder)
                .toggleStyle(.checkbox).font(.system(size: 12))
            HStack {
                Spacer()
                Button("稍后", action: finish).keyboardShortcut(.cancelAction)
                Button("打开系统设置…", action: access.openFullDiskAccess).keyboardShortcut(.defaultAction)
            }
        }.padding(24).frame(width: 490).fixedSize(horizontal: false, vertical: true)
            .modifier(AppIconAppearance())
    }
}
