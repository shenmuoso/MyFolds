# MyFolds 图标重设计 — 2026-11-21

上一版被用户否定：双面五官与 Finder 过于接近；渐变与白色叠片未呈现可信的玻璃质感。本轮仅探索应用图标，不改变主界面和已确认的窗口磨砂效果。

推荐方向 A：折叠文件夹。文件夹后片、内部文件、磨砂前片、卷折边分别成层。以卷折边呼应 Folds，文件管理的含义清楚，前后遮挡也让玻璃透色更容易读到。
方向 B：双面折页。两扇打开的文件页，加一层回折页，保留 Finder 双面的呼应。轮廓更简洁，但也更容易被读作书本，因此作为备选。

颜色由冰青、透白和小面积蓝紫组成。底板为系统形状的中性玻璃面；不使用 Finder 原有的蓝白半脸分割、两只眼睛和横跨全图的笑线。玻璃高光、折射、磨砂和投影交给 Apple Icon Composer，输入 SVG 只包含独立几何层，不预烘焙高光或阴影。

先交付原生渲染的浅/深背景和 Dock 尺寸预览。这批为候选设计，不代表用户已接受，不覆盖当前应用包。

## 本轮完成

- 两个可编辑的原生 `.icon` 工程，分别三组、四组。
- 修正文件夹左侧轮廓的折点；收起折页底部多余露出的后片。
- 原生磨砂、折射、边缘高光、层间阴影；SVG 仅定义轮廓和基础色。
- 文件夹前片：Blur 12%、Translucency 92%、Refraction Strength 85% / Depth 32%、Specular Inside、Shadow 24%。其余层参数保存在生成脚本中。
- 以 Apple `ictool`、`--design-generation 27` 导出 Default / Dark，两种设计均有 32、64、128、1024 px。
- Icon Composer 已打开文件夹工程；界面确认四组四层、Generation 27、上述材质参数以及深色渲染正确加载。
- 组合预览使用中性浅灰和炭灰背景，未修改导出图的色彩或材质；缩放仅用于排版。
- 已逐图查看组合板和 32 / 64 / 128 px 原尺寸板：32 px 下主要依靠轮廓、蓝色后片和明暗关系识别，细微折射在 64 px 以上更明显。A 的文件夹语义保留更好；B 的书本联想仍然存在。

## 文件与复现

- `MyFolds-Folder.icon`：推荐方向的原生源文件。
- `MyFolds-Fold.icon`：备选方向的原生源文件。
- `previews/MyFolds-comparison.png`：两个方向的浅色与深色对照。
- `previews/MyFolds-native-sizes.png`：原始像素尺寸检查，查看时保持 100% 比例。
- `python3 build-candidates.py`：使用已安装的 Icon Composer 渲染器重新导出。
- `make-preview-board.py`：用 Pillow 将导出图排版成预览；不生成或伪造玻璃效果。

本次未使用图片生成 API。没有替换 `resources/MyFolds.svg`、已安装应用图标或 DMG。应用接入、系统 Dock 的实际效果需在方向确认后单独验证；本轮图片是原生图标渲染器的设计预览。

## 方向确认 — 2026-11-21

用户回复「A吧」，确认 A「折叠文件夹」。生产源文件复制到 `resources/AppIcon.icon`，0.1.8 开始以此作为应用图标；B 保留为未采用候选。上面的“未替换”描述记录设计预览交付时的状态。

0.1.9 修正旧图标缓存引用：生产源改名为 `resources/MyFoldsIcon.icon`，内容保持与 A 一致。应用内和运行中的 Dock 使用同源导出的浅色/深色资源，随 MyFolds 外观切换；访达保留原生图标栈。该改名及主题联动不改变已批准的造型。

官方依据：
- https://developer.apple.com/icon-composer/
- https://developer.apple.com/design/human-interface-guidelines/app-icons
- https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer
