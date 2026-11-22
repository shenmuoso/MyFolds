# MyFolds

macOS 原生文件管理器。SwiftUI 界面与 AppKit 文件列表、窗口和媒体预览；底层文件操作和压缩处理独立于界面。

当前为 **0.1.11 内部测试版**，提供真实文件浏览、剪切/复制/粘贴、完整路径、双栏独立标签、快速访问、内置编辑与媒体查看、打开方式、DMG 挂载和压缩包操作。本版新增“偏好设置 → 文本编辑器”：行号、字体与字号、独立外观、修饰键滚轮缩放开关，以及可录入的查找/替换快捷键。编辑器支持单文件普通、转义和正则搜索，结果列表、选区范围、逐个/全部替换与撤销。HTML 确认稿保留在 `outputs/myfolds-design/`，功能范围草案不等于本构建全部完成。

## 运行与构建

- Apple Silicon Mac，macOS 27.0 或更新系统。
- Xcode 27.2 / Swift 6.4；无需下载 Swift 包依赖。
- 使用 macOS 自带 libarchive。`Sources/CArchive/include/` 为上游公开头文件；许可见 `resources/ThirdPartyNotices.txt`。

```bash
swift test
bash scripts/build-app.sh debug
bash scripts/package-dmg.sh
```

调试应用：`.build/Preview/MyFolds.app`。
发布应用：`.build/Release.noindex/MyFolds.app`；DMG：`outputs/releases/`。
发布应用使用不索引的构建目录，避免系统启动列表把它与 `/Applications` 中的安装版重复登记。

调试包显示为 `MyFolds Preview`，使用独立标识 `com.myfolds.app.preview`，避免系统 App 列表把预览版与安装版合并。调试偏好与安装版分开保存。

本机旧版备份保存在 `work/app-backups.noindex/`，扩展名为 `.app-backup`，不作为可启动应用登记。需要恢复时先复制到临时位置，再将扩展名改回 `.app`；不要直接在工作目录堆放同标识的旧 `.app` 包。2026-11-22 的迁移路径与内容哈希见 `work/app-list-repair-2026-11-22/backup-moves.json`。

DMG 使用本地 ad-hoc 签名，尚无 Developer ID 签名与 Apple 公证。它供当前阶段本机测试，不是公开分发包。

## 文件组织

- `Sources/MyFolds/`：原生界面、窗口桥接、浏览状态及偏好。
- `Sources/MyFoldsCore/`：文件系统、校验、撤销记录、压缩包读写。
- `Tests/MyFoldsCoreTests/`：真实临时文件操作与格式、安全边界测试。
- `Tests/MyFoldsUITests/`：打开规则、导航、编辑器、外观与窗口材质回归。
- `resources/IconArtwork/`：用户截图、去底并对齐的 1024 px 母版及处理记录；可由 `scripts/prepare-icon-artwork.py` 重建。
- `resources/MyFoldsFolder.icon`：当前图标源文件；用户图稿保留原有光影，macOS 提供系统容器与外观。旧 `MyFoldsIcon.icon` 不再参与构建。
- `scripts/build-icons.sh`：由当前图标源文件生成 `Assets.car`、兼容 ICNS、图标元数据及浅深色品牌图；系统、应用内与 Dock 共用同一图稿。
- `scripts/`：图标、应用包及 DMG 的可复现构建脚本。
- `outputs/myfolds-design/`：此前确认的交互设计，使用示例数据。

具体覆盖范围与限制见 [原生测试版说明](原生测试版说明.md)。
