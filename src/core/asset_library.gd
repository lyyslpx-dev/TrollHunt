extends Node
## 资产库：按 ID 从 data/asset_manifest.json 找模型。
## 文件不存在时返回 null，调用方回退到占位几何体，换模型不用改代码。

const MANIFEST_PATH := "res://data/asset_manifest.json"

var _data: Dictionary = {}


func _ready() -> void:
	_load_manifest()


func _load_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_warning("资产清单缺失：%s" % MANIFEST_PATH)
		return
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_data = parsed


func get_entry(id: String) -> Dictionary:
	for section_name in ["characters", "outfits", "monsters", "environment", "weapons"]:
		var section: Dictionary = _data.get(section_name, {})
		if section.has(id):
			return section[id]
	return {}


func has_model(id: String) -> bool:
	var entry := get_entry(id)
	var path := String(entry.get("model", ""))
	return not path.is_empty() and ResourceLoader.exists(path)


func instantiate(id: String) -> Node3D:
	var entry := get_entry(id)
	var path := String(entry.get("model", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource := load(path)
	if resource is PackedScene:
		var node := (resource as PackedScene).instantiate()
		if node is Node3D:
			return node as Node3D
		node.queue_free()
	return null


func model_path(id: String) -> String:
	var entry := get_entry(id)
	return String(entry.get("model", ""))

