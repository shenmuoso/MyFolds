import SwiftUI

struct AccessSettings: View {
    @Bindable var access: FileAccessManager
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Label("完全磁盘访问权限", systemImage: "externaldrive.badge.checkmark").font(.headline)
                Text("首次使用时，在系统设置中添加 MyFolds 并开启权限，统一访问桌面、文稿、下载和受保护目录。系统可能要求退出并重新打开应用。")
                    .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Button("打开系统设置…", action: access.openFullDiskAccess)
                Text("隐私与安全性 → 完全磁盘访问权限 → ＋ → 应用程序 → MyFolds")
                    .font(.system(size: 11)).foregroundStyle(.secondary).textSelection(.enabled)
            }
            Divider().opacity(0.25)
            VStack(alignment: .leading, spacing: 8) {
                Label("记住目录授权", systemImage: "folder.badge.plus").font(.headline)
                Text("也可以授权个人文件夹或指定磁盘。已授权目录会在下次启动时恢复；系统保护的目录仍需要上方的完全磁盘访问权限。")
                    .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Button("选择并授权目录…", action: access.chooseRoot)
                ForEach(access.authorizedPaths, id: \.self) { path in
                    Label(path, systemImage: "checkmark").font(.system(size: 11)).lineLimit(1).truncationMode(.middle).help(path)
                }
            }
            if let message = access.message { Text(message).font(.caption).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
