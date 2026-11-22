# TrollHunt

Q 版传奇手游，2.5D 斜 45 度固定视角，TrollStore 安装。
Godot 4.7.2 + GDScript + Blender 5.2。

## 一句话
Q 版大头角色，刷怪爆装、强化、打 BOSS 的横屏传奇式手游。

## 会话启动
1. 读 `docs/STATUS.md`
2. 读与本任务相关的文档（见索引）
3. 只改自己负责的目录

## 硬约束
- iOS deployment target 14.0，arm64，单包覆盖 TrollStore 14.0–16.6.1 / 16.7 RC / 17.0
- 最低机型 iPhone 12（A14 / 4GB）60fps；主力 iPhone 12 Pro（iPhone13,3，iOS 14.7）60fps；发热时可动态降到 45/30
- 渲染器只用 Mobile（Metal / MoltenVK）
- 相机固定：正交投影，俯角 45°，偏航 45°，不提供自由旋转
- 角色 3D 低模 + 卡通着色 + 描边；技能特效走 2D 叠加层
- Overdraw 预算：iPhone 12 最多 3 层全屏加色，iPhone 12 Pro 最多 4 层
- 贴图 ASTC；pck 加密必须关闭
- 不提交密钥、证书、账号

## 画质档位
| 档 | 机型 | 3D 缩放 | 描边 | 特效 | 帧率 |
|---|---|---|---|---|---|
| 低 | iPhone 12 / A14 | 0.75 | 开 | 70% | 60 |
| 中 | iPhone 12 Pro / 13 | 0.85 | 开 | 85% | 60 |
| 高 | iPhone 15+ | 1.00 | 开 | 100% | 60 |

自动档只决定首次默认值。玩家手动修改后进入 `custom`，任何逻辑不得覆盖。

## 文档索引
| 任务 | 先读 |
|---|---|
| 玩法 / 数值 / 关卡 | `docs/GDD.md` |
| 工程 / 设置 / 性能 | `docs/TECH.md` |
| 美术 / 模型 / 特效 | `docs/ART.md` |
| 构建 / IPA / 安装 | `docs/BUILD.md` |

## 目录职责
- `src/core`：autoload、存档、事件总线
- `src/gameplay`：战斗、技能、AI、掉落
- `src/ui`：HUD、背包、装备、设置
- `assets`：模型、贴图、特效、音频
- `data`：装备表、怪物表、掉落表
- `tools`：构建与资源脚本
- `docs`：规格与状态

## 协作规则
- 一个会话只改职责内目录；跨目录改动先写进 `docs/STATUS.md`
- 完成后更新 `STATUS.md` 和 `DECISIONS.md`
- 数值放 `data/`，不硬编码

