extends Node
## 全局信号总线。跨模块通信只走这里，不直接互相引用。

signal damage_dealt(target: Node, amount: int, is_crit: bool)
signal enemy_died(enemy: Node)
signal player_died
signal loot_dropped(item_id: String, world_position: Vector3)
signal item_picked(item_id: String)
signal loot_picked(item: Resource)
signal player_stats_changed
signal camera_shake(strength: float)
signal settings_changed(key: String, value: Variant)
signal npc_prompt_changed(text: String, visible: bool)
signal npc_upgrade_requested
signal npc_teleport_requested
signal npc_riddle_requested
signal zone_prompt_changed(text: String, visible: bool)
signal map_changed(map_id: String)
signal travel_requested(map_id: String)

