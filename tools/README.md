# 构建工具

两条链路：

1. **底包（GitHub Actions）**：macOS runner 用 Godot 4.7.2 导出 Xcode 工程，`xcodebuild` 关闭签名构建 `.app`，`ldid -S` 伪签名，打包成未签名 `.ipa`。
2. **日常迭代（Windows）**：本地 Godot 4.7.2 导出 `game.pck`，用 `pack_pck.ps1` 替换进底包 `.app`，TrollStore 安装。

## 底包：GitHub Actions

工作流：`.github/workflows/ios.yml`

触发：
- 推送到 `main`
- 或在 Actions 页面手动 `Run workflow`

前置条件：
- 仓库里有 `project.godot`
- `export_presets.cfg` 中有名为 `iOS` 的预设
- 预设已填 bundle identifier，项目有图标，并开启 ETC2/ASTC 纹理导入
- Godot 版本固定 4.7.2；工作流会下载官方 macOS 编辑器和 iOS 导出模板

产物：
- Artifact：`TrollHunt-ios-unsigned`
- 文件：`Game.ipa`
- 保留 90 天

工作流内部步骤：Godot 导出 Xcode 工程 → `xcodebuild`（`CODE_SIGNING_ALLOWED=NO`）→ `ldid -S` 主可执行文件 → `Payload/*.app` 压成 `.ipa`。

`ci_prepare_ios_preset.py` 是 CI 辅助脚本：把 `iOS` 预设的 `application/export_project_only` 强制设为 `true`，并拒绝 `encrypt_pck=true` / `encrypt_directory=true`。本地不要依赖它改配置。

## 日常迭代：Windows 替换 PCK

### 1. 导出 PCK

在项目根目录：

```powershell
godot --headless --path . --export-pack "iOS" build/game.pck
```

要求：
- Godot 必须是 **4.7.2**
- 导出预设用与底包相同的 `iOS`
- PCK 加密必须关闭
- 文件名必须是 `game.pck`（脚本会校验）

### 2. 替换并重打包

```powershell
.\tools\pack_pck.ps1 `
  -Ipa .\build\TrollHunt-base.ipa `
  -Pck .\build\game.pck `
  -Out .\build\TrollHunt-20261120.ipa
```

如果执行策略阻止脚本：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\pack_pck.ps1 `
  -Ipa .\build\TrollHunt-base.ipa `
  -Pck .\build\game.pck `
  -Out .\build\TrollHunt-20261120.ipa
```

脚本做什么：
- 校验输入存在、扩展名、`game.pck` 文件名
- 读取底包内 `Payload/*.app/game.pck` 和本地 PCK 的 Godot 版本头，版本不一致直接报错
- 复制底包，在 zip 中原位替换 `game.pck`，其余条目（包括 Mach-O、权限、符号链接）保持不动
- 校验条目数量和 PCK 大小，然后写出 `-Out`
- 不修改 Mach-O，不做重签名

> 实现上没有“先整包解压再重新压缩”，因为 Windows 解压/压缩会丢失 Unix 可执行位和符号链接。原位替换达到同样结果，但更安全。

### 3. 安装

TrollStore → 打开输出 `.ipa` → Install。

## 限制

- 只适用于 TrollStore；未签名 IPA 不能直接用 Xcode / AltStore / 企业签名安装。
- 底包的 iOS deployment target 是 14.0，目标系统 iOS 14.0–17.0。
- PCK 热替换只换游戏数据，不换 Godot 引擎、导出模板、原生插件或 `Info.plist`。
- PCK 的 Godot 版本和 pack 格式必须与底包完全一致，否则脚本拒绝输出。
- 加密 PCK 不支持；导出时必须关闭加密。
- 首次底包必须由 CI（或任意 macOS + Xcode）产出；Windows 只能做后续 PCK 替换。
- GitHub artifact 只保留 90 天，底包请下载后自行归档。

## 常见错误

| 现象 | 原因 |
|---|---|
| `底包内没有找到 Payload/*.app/game.pck` | 不是 Godot iOS 包，或包结构被改过 |
| `PCK 文件名必须是 game.pck` | 导出文件名不对，重命名后再运行 |
| `Godot 版本不一致` | 本地 Godot 不是 4.7.2，或底包来自其他版本 |
| `不是有效的 Godot PCK` | 文件不是 PCK，或被加密/截断 |
| CI 提示缺少 `project.godot` / `export_presets.cfg` | 工程骨架或 iOS 预设还没提交 |
| CI 找不到 `Game.xcodeproj` | 预设不是 `export_project_only=true`，或导出失败 |
