# 构建与安装

## 本地开发
- Windows 上用 Godot 桌面窗口预览
- 导出 `.pck` 需要安装 4.7.2 导出模板

## 底包（CI）
- GitHub Actions macOS runner，公开仓库免费
- 安装 Godot 4.7.2 + iOS 模板 → 导出 Xcode 工程 → `xcodebuild CODE_SIGNING_ALLOWED=NO` → `ldid -S` → `Payload` 打包 `.ipa`
- artifact 保留 90 天

## 日常迭代
1. 导出 `game.pck`
2. 解压底包，替换 `.app` 内的 `game.pck`
3. 重新压缩成 `.ipa`
4. TrollStore 安装

不改 Mach-O，不需要重签。pck 加密必须关闭，Godot 版本必须与底包一致。

## 安装
TrollStore → 打开 ipa → Install。

## 兼容范围
iOS 14.0–16.6.1、16.7 RC、17.0。

