import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                WindowControls().frame(width: 70, height: 22)
                Spacer()
            }.padding(.horizontal, 17).frame(height: 46)
                .background { WindowDragArea() }
            VStack(spacing: 12) {
                Image(AppIconProvider.assetName, bundle: .main)
                    .resizable().scaledToFit().frame(width: 88, height: 88)
                    .accessibilityHidden(true)
                VStack(spacing: 5) {
                    Text("MyFolds").font(.system(size: 23, weight: .semibold))
                    Text("版本 \(AppInformation.versionLabel)").font(.system(size: 12)).foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                Text("macOS 原生文件管理器").font(.system(size: 13))
                HStack(spacing: 6) {
                    Text("作者").foregroundStyle(.secondary)
                    Link(AppInformation.author, destination: AppInformation.authorURL)
                }.font(.system(size: 12))
                Link(destination: AppInformation.projectURL) {
                    Label("GitHub 项目", systemImage: "arrow.up.right")
                }.font(.system(size: 12))
            }.padding(.top, 4)
            VStack(alignment: .leading, spacing: 8) {
                Text("作者的其他项目").font(.system(size: 11)).foregroundStyle(.secondary)
                Link(destination: AppInformation.recommendedProjectURL) {
                    HStack {
                        Text("mac-scope").font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .medium))
                    }
                }
                Text("macOS 资源监控与系统清理工具")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }.padding(.horizontal, 34).padding(.top, 30)
            Spacer(minLength: 20)
        }.frame(width: 420, height: 430)
            .onExitCommand { NSApp.keyWindow?.performClose(nil) }
    }
}
