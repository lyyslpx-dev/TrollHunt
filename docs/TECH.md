# 技术规格

## 引擎
- Godot 4.7.2，GDScript 静态类型
- Mobile 渲染器，iOS deployment target 14.0

## 相机
- Camera3D，`projection = ORTHOGONAL`
- 旋转 `(-45, 45, 0)`，orthogonal size 约 8–10
- 跟随玩家，0.15 秒平滑

## 渲染分层
| 层 | 内容 |
|---|---|
| Layer 0 | 3D 场景与角色 |
| CanvasLayer 10 | 2D 技能特效 |
| CanvasLayer 20 | 伤害飘字 |
| CanvasLayer 30 | HUD |
| CanvasLayer 40 | 弹窗与 tooltip |

## Autoload
`Settings`、`GameState`、`Events`、`Audio`、`Save`

## 战斗
- 自动索敌取最近目标，超过 6 米不攻击
- 技能冷却与 0.3 秒公共 CD
- 伤害统一走 `DamageEvent`，不直接改 HP
- 飘字对象池 64 个

## 数据
- `ItemData`（Resource）：id、名称、部位、品质、基础属性、附加属性、图标
- `MonsterData`：血量、攻击、防御、速度、掉落表
- `DropTable`：权重表
- 全部放 `data/*.tres`

## 设置
| 键 | 范围 |
|---|---|
| graphics/preset | auto / low / mid / high / custom |
| graphics/render_scale | 0.5–1.0 |
| graphics/shadows | off / low / high |
| graphics/fx_intensity | 0–1（同时控制粒子数与叠加层数） |
| graphics/post | bool |
| graphics/msaa | off / 2x |
| graphics/fps_cap | 30 / 60 / 0 |
| graphics/dynamic_resolution | bool |

## 性能预算
| 档 | 三角面 | Draw call | 粒子 | 全屏加色层 |
|---|---|---|---|---|
| 低 | 70k | 100 | 300 | 3 |
| 中 | 100k | 140 | 500 | 4 |
| 高 | 150k | 180 | 700 | 4 |

## 存档
- `user://save.json`，带版本号字段
- 版本升级时做迁移，不直接覆盖旧档

