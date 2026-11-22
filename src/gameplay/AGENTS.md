# 战斗代码约定

- 只改本目录
- 状态机用 enum + match，不用节点堆叠
- 伤害统一走 `DamageEvent`，不直接改 HP
- 数值从 `data/` 读，不硬编码
- 命中特效走 FX 对象池，不每次 instantiate

