# 美术资产清单与替换规范

## 命名规则
`类型_类别_序号`，全大写，下划线分隔。

- `CHR_` 角色
- `MON_` 小怪
- `BOSS_` 首领
- `ENV_` 场景
- `WPN_` 武器
- `UI_` 界面
- `FX_` 特效
- `SFX_` 音效

## 替换契约（所有模型必须满足）
- 单位：1 米 = 1 单位。
- 朝向：-Z 为正面。
- 原点：脚底中心，y = 0。
- 缩放：导出前应用变换，scale 为 1。
- 材质：一个主材质 + 一张 1024 图集，允许顶点色。
- 动画名固定：`idle`、`run`、`attack1`、`attack2`、`attack3`、`hit`、`die`。
- 骨骼不超过 50，蒙皮权重不超过 4。
- 换模型只换文件，ID 和路径不变，代码不改编。

## 角色
| ID | 名称 | 面数 | 贴图 | 说明 |
|---|---|---|---|---|
| CHR_WARRIOR_01 | 赤霄卫 | 20k | 2048 | 重甲巨剑，红金配色 |
| CHR_MAGE_01 | 星火阁 | 20k | 2048 | 长袍法杖，深蓝配色 |
| CHR_TAOIST_01 | 青木观 | 20k | 2048 | 符扇与灵兽，白黄配色 |
| WPN_SWORD_01 | 赤霄巨剑 | 3k | 1024 | 战士主武器 |
| WPN_STAFF_01 | 星火法杖 | 3k | 1024 | 法师主武器 |
| WPN_FAN_01 | 镇魂符扇 | 3k | 1024 | 道士主武器 |

每个职业还需要：选人立绘 1 张、头像 1 张、技能图标 4 个。

### 男性角色约束

三名可玩职业全部为男性。立绘、头像、五套等级外观与游戏内模型必须保持同一男性脸型，不生成女性换装版本。

### 职业等级套装

等级按 10/20/30/50 分档，每个职业 5 套，共 15 套。同一职业的五套共用骨架、动作和动画名；换装只替换网格与材质，不改变战斗数值。装备靠打怪掉落，玩家达到对应等级后才能穿戴；未穿戴时显示基础身体与默认短裤。

| 职业 | 档位 | 等级 | 套装 ID | 名称 | 视觉方向 |
|---|---|---|---|---|---|
| 战士 | I | 1–9 | CHR_WARRIOR_SET_01 | 新兵皮甲 | 粗皮甲、青铜护肩、短剑 |
| 战士 | II | 10–19 | CHR_WARRIOR_SET_02 | 精铁战甲 | 银灰板甲、红披风、金边 |
| 战士 | III | 20–29 | CHR_WARRIOR_SET_03 | 赤金重铠 | 赤红金纹板甲、多层肩甲 |
| 战士 | IV | 30–49 | CHR_WARRIOR_SET_04 | 龙鳞血铠 | 暗红龙鳞、黑金纹饰、长披风 |
| 战士 | V | 50–60 | CHR_WARRIOR_SET_05 | 天命炎铠 | 赤金神话甲、符文、王冠盔 |
| 法师 | I | 1–9 | CHR_MAGE_SET_01 | 学徒法袍 | 钴蓝短袍、极简金边 |
| 法师 | II | 10–19 | CHR_MAGE_SET_02 | 秘银星袍 | 蓝袍、银金肩甲、水晶杖 |
| 法师 | III | 20–29 | CHR_MAGE_SET_03 | 星辉法衣 | 蓝紫叠层、星纹、悬浮晶片 |
| 法师 | IV | 30–49 | CHR_MAGE_SET_04 | 天穹星袍 | 深蓝金线、星座纹、长袍 |
| 法师 | V | 50–60 | CHR_MAGE_SET_05 | 天命星冠 | 午夜蓝与象牙白、金冠、符文 |
| 道士 | I | 1–9 | CHR_TAOIST_SET_01 | 白木道袍 | 白袍、浅黄腰带、木符 |
| 道士 | II | 10–19 | CHR_TAOIST_SET_02 | 黄符云袍 | 白黄袍、黑边、纸符 |
| 道士 | III | 20–29 | CHR_TAOIST_SET_03 | 青玉灵袍 | 青白玉色、云纹、灵狐 |
| 道士 | IV | 30–49 | CHR_TAOIST_SET_04 | 太极金袍 | 象牙白与金、八卦纹、灵兽 |
| 道士 | V | 50–60 | CHR_TAOIST_SET_05 | 天命玄袍 | 白金神话袍、悬浮玉环、灵兽虚影 |

概念设定图：

- `assets/concept/classes/warrior_sets.png`
- `assets/concept/classes/mage_sets.png`
- `assets/concept/classes/taoist_sets.png`

### 安全区 NPC

| ID | 名称 | 资产 | 状态 |
|---|---|---|---|
| CHR_NPC_UPGRADE_01 | 升级大师·胖哥 | `assets/models/chr/npc/CHR_Npc_Upgrade_01.glb` | 3D 已接入，头顶破面待修 |

- 当前 3D：8,622 三角面、52 骨骼、每顶点最多 4 权重、单材质、2K Diffuse/Normal + Metallic-Roughness。
- 来源：Hyper3D `base.usdz`（骨骼）+ `base_basic_pbr.usdz`（贴图），网格未修形；头顶发簇破面按用户要求原样保留。
- 朝向：glTF 导入 Godot 后正面为 +Z，`upgrade_npc.gd` 按固定相机偏航转向镜头；高度按 1.85 / 1.908 缩放。
- 2D 立绘保留为回退：`assets/sprites/npc/upgrade_npc_*.png`（`idle`、`hammer`、`wipe`、`stretch`）。
- 暂未制作骨骼动作与表情；脚本只做程序化待机、挥锤、擦汗、伸懒腰的轻微位移。
- 安全区半径 3.5 米，敌人不得进入或攻击。
- 后续换模型时保留同一 NPC ID、交互节点和碰撞体。

最终 3D 参考：`assets/concept/characters/character_01_final_npc_ref.png`。

最终品质目标：

- 20–30k 面，30–40 根骨骼，每顶点最多 4 个权重。
- 2K PBR：Albedo、Normal、Roughness、AO，皮肤另带假 SSS 遮罩。
- 6 个表情：正常、开心、生气、伤心、惊讶、困。
- 6 个动作：`idle`、`hammer`、`wipe`、`stretch`、`look`、`talk`。
- 保留大肚腩、短腿、粗手臂、灰发胡茬和蓝底菱形短裤的轮廓。
- 参考图是带光照的设定图，不能直接当贴图使用；贴图必须重新绘制和烘焙。

### 3D 原型（仅验证）

| 职业 | 文件 | 面数 | 状态 |
|---|---|---|---|
| 战士 | `assets/models/chr/prototype/CHR_Warrior_Prototype_8k.glb` | 7,996 | 静态白模 |
| 法师 | `assets/models/chr/prototype/CHR_Mage_Prototype_8k.glb` | 7,996 | 静态白模 |
| 道士 | `assets/models/chr/prototype/CHR_Taoist_Prototype_8k.glb` | 7,992 | 静态白模 |

- 来源：Hunyuan3D 2.1 官方 Space 免费额度。
- 当前模型没有骨骼、动画和贴图，拓扑与脸部需要重做。
- Hunyuan3D 2.1 为非商用许可，只能用于原型验证，不能直接作为商业版本最终资产。
- 同屏校验场景：`scenes/prototype_lineup.tscn`。
- 8k 白模只用于验证体块；最终角色按 20–30k 面、2K PBR 图集制作。

## 怪物（按地图）
| 地图 | 小怪 | 精英 | BOSS |
|---|---|---|---|
| 黄沙岗 | 沙鼠、瘦狼 | 无 | 无 |
| 沙地遗迹 | 野猪、弓手、自爆虫 | 牛魔 | 沙虫王 |
| 幽影森林 | 毒藤、树精、暗影弓手 | 腐化德鲁伊 | 千年树妖 |
| 寒霜堡垒 | 冰狼、冰法、重装卫兵 | 霜巨魔 | 冰霜巨龙 |
| 熔岩深渊 | 火魔、熔岩兽、自爆火虫 | 炎狱犬 | 炎魔 |
| 黄泉鬼域 | 鬼兵、怨灵、尸巫 | 勾魂使者 | 鬼王 |
| 天空浮岛 | 风灵、雷鸟、石像守卫 | 风暴祭司 | 雷鹏 |
| 海底龙宫 | 虾兵、蟹将、水法 | 龟丞相 | 龙王 |
| 魔域血月 | 魔将、血卫、魔女 | 深渊领主 | 魔尊 |
| 擂台 | 无 | 无 | 每 5 波 |

面数：小怪 4–6k，精英 8–12k，BOSS 20–35k。使用 1024–2048 图集。

## 场景
每张地图至少四件：地砖 A/B、地标 1、道具 2、加载图 1。

| 地图 | 地砖 | 地标 | 道具 |
|---|---|---|---|
| 黄沙岗 | ENV_ASHEN_TILE_A/B | 枯树 | 破车、石堆 |
| 沙地遗迹 | ENV_RUIN_TILE_A/B | 断裂石柱 | 半埋雕像、沙丘 |
| 幽影森林 | ENV_FOREST_TILE_A/B | 巨树 | 荧光蘑菇、藤蔓 |
| 寒霜堡垒 | ENV_FROST_TILE_A/B | 冰封塔楼 | 火盆、冰晶 |
| 熔岩深渊 | ENV_LAVA_TILE_A/B | 熔岩瀑布 | 铁链、黑岩 |
| 黄泉鬼域 | ENV_UNDERWORLD_TILE_A/B | 鬼门 | 灯笼、骨堆 |
| 天空浮岛 | ENV_SKY_TILE_A/B | 风眼 | 浮岩、风带 |
| 海底龙宫 | ENV_PALACE_TILE_A/B | 龙王殿 | 珊瑚、气泡 |
| 魔域血月 | ENV_BLOOD_TILE_A/B | 血月尖塔 | 血池、枯枝 |
| 擂台 | ENV_ARENA_TILE_A/B | 中央石台 | 火盆、旗帜 |

### 地面材质 v1

- 20 张 512×512 无缝地面已完成：每张地图 A/B 各一张，位于 `assets/textures/env/ground/`。
- 10 块纯地面参考裁切位于 `assets/concept/maps/ground_regions/`，只用于取样，不进运行时平铺。
- 主题、配色、光照、危险区域和 A/B 角色写在 `data/map_themes.json`。
- `MapThemes` autoload 负责读表与建材质；`src/gameplay/map_environment.gd` 负责套用到主场景。
- 黄沙岗 100×100 白盒布局在 `data/map_layouts.json`，运行时由 `src/gameplay/map_layout.gd` 铺出。
- 当前主场景默认 `MAP_01_ASHEN_YARD`；切换 `map_id` 即可验证其余主题。
- 材质清单同时登记在 `data/asset_manifest.json` 的 `ground_materials`。

### Hyper3D 批量资产

- `work/hyper_batch_jobs.json` 定义首批怪物、道具、武器；产物暂存 `work/hyper_assets`。
- `work/integrate_hyper_assets.py` 会把完成的 GLB 复制到 `assets/models` 并更新 manifest。
- `CHR_CUSTOM_MALE_01.glb` 已入库：`assets/models/chr/custom/CHR_CUSTOM_MALE_01.glb`。
- 首批 14 件 Hyper3D 资产已全部入库，怪物/场景道具/武器分别归入 `assets/models/mon`、`env`、`wpn`。

## UI
- `UI_HUD_FRAME` 主 HUD 框
- `UI_PANEL_WOOD` 通用木纹弹窗
- `UI_BTN_GOLD` 主按钮
- `UI_SLOT_ITEM` 装备格
- `UI_QUALITY_01..07` 七档品质边框
- `UI_ICON_ATTACK`、`UI_ICON_SKILL_01..04`
- `UI_MAP_CARD_01..10` 十张地图卡片
- `UI_LOGO` 游戏 Logo

## 特效
`FX_SLASH`、`FX_HIT_SPARK`、`FX_WHIRLWIND`、`FX_CHARGE`、`FX_THUNDER`、`FX_ICE_BURST`、`FX_LAVA_ERUPT`、`FX_DEATH_DISSOLVE`、`FX_LOOT_BEAM`、`FX_LEVEL_UP`

## 音效
`SFX_SWING`、`SFX_HIT`、`SFX_CRIT`、`SFX_SKILL_01..04`、`SFX_LEVEL_UP`、`SFX_LOOT`、`SFX_BOSS_ROAR`

## 资产目录
```
assets/
  models/chr/ mon/ env/ prop/ wpn/
  textures/chr/ mon/ env/ ui/
  vfx/
  ui/
  audio/sfx/ bgm/
  concept/
```

## 替换流程
1. 新文件命名为同一个 ID，放进对应目录。
2. 保持原点、朝向、动画名不变。
3. 更新 `data/asset_manifest.json` 里的路径（如果文件名带版本号）。
4. 跑一次 `--headless --quit` 验证导入。

## 面数与贴图总预算
| 档 | 单帧三角面 | Draw call | 贴图内存 |
|---|---|---|---|
| 低 | 35k | 80 | 250MB |
| 中 | 70k | 120 | 400MB |
| 高 | 120k | 160 | 600MB |

