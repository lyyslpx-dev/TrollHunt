# 会话分工与启动提示词

每个新会话第一句都带上工作目录，否则它不知道项目在哪。

## 会话 1：设计

```
工作目录：C:\Users\Administrator\Documents\Codex\TrollHunt
先读 AGENTS.md、docs/STATUS.md、docs/GDD.md。
你负责玩法设计。按 Q 版传奇 2.5D 方向补完 GDD：
三个职业的技能表、八部位装备表、品质与附加属性规则、掉落权重、
强化曲线、1–30 级经验曲线、沙地遗迹的怪物配置。
写回 docs/GDD.md，并更新 docs/STATUS.md。不要写代码。
```

## 会话 2：工程

```
工作目录：C:\Users\Administrator\Documents\Codex\TrollHunt
先读 AGENTS.md、docs/TECH.md、docs/STATUS.md。
你负责工程。搭 Godot 4.7.2 骨架：正交相机（-45, 45, 0）、
角色移动与摇杆、技能栏、HUD、设置页、Settings/GameState/Events/Audio/Save
五个 autoload、data 下的 ItemData 和 MonsterData。
只改 project.godot、src/core、src/ui。完成后更新 docs/STATUS.md。
```

## 会话 3：战斗

```
工作目录：C:\Users\Administrator\Documents\Codex\TrollHunt
先读 AGENTS.md、docs/STATUS.md、docs/GDD.md、docs/TECH.md。
你负责战斗。自动索敌、普攻三段、四个技能、伤害计算、暴击、
飘字对象池、受击闪白与击退、掉落与拾取、地面品质光柱。
只改 src/gameplay。依赖 autoload，不存在就先建最小版本并在 STATUS 标注。
```

## 会话 4：美术

```
工作目录：C:\Users\Administrator\Documents\Codex\TrollHunt
先读 AGENTS.md、docs/ART.md、docs/STATUS.md。
你负责美术。用 Blender 5.2 无头模式产出：Q 版战士白模（2.5 头身）、
野猪/弓手/自爆虫三个小怪白模、沙地遗迹地砖模块，
按 docs/ART.md 的面数，导出 glTF 到 assets/models。更新 docs/STATUS.md。
```

## 会话 5：构建

```
工作目录：C:\Users\Administrator\Documents\Codex\TrollHunt
先读 AGENTS.md、docs/BUILD.md、docs/STATUS.md。
你负责构建。检查现有 .github/workflows/ios.yml 和 tools/pack_pck.ps1，
按当前项目补齐缺失项，更新 docs/BUILD.md 和 docs/STATUS.md。
只改 .github 和 tools。
```

## 依赖关系

- 1 设计、2 工程、5 构建可以同时开
- 3 战斗依赖 2 工程
- 4 美术依赖 1 设计给出怪物配置

## 每个会话结束前

1. 更新 `docs/STATUS.md` 的“已完成 / 下一步”
2. 新决策追加到 `docs/DECISIONS.md`
3. 跑不通的问题写进 `docs/STATUS.md` 的“开放问题”

