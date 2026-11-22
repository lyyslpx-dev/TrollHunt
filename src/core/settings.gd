extends Node
## 画质设置。
## 自动档只在首次启动时决定默认值；玩家手动修改后进入 custom，不再被覆盖。

signal changed(key: String, value: Variant)

const CONFIG_PATH := "user://settings.cfg"

const PRESETS := {
	"low": {
		"graphics/render_scale": 0.75,
		"graphics/shadows": "low",
		"graphics/fx_intensity": 0.70,
		"graphics/post": true,
		"graphics/msaa": "off",
		"graphics/fps_cap": 60,
		"graphics/dynamic_resolution": true,
	},
	"mid": {
		"graphics/render_scale": 0.85,
		"graphics/shadows": "high",
		"graphics/fx_intensity": 0.85,
		"graphics/post": true,
		"graphics/msaa": "off",
		"graphics/fps_cap": 60,
		"graphics/dynamic_resolution": true,
	},
	"high": {
		"graphics/render_scale": 1.00,
		"graphics/shadows": "high",
		"graphics/fx_intensity": 1.00,
		"graphics/post": true,
		"graphics/msaa": "off",
		"graphics/fps_cap": 60,
		"graphics/dynamic_resolution": true,
	},
}

const PRESET_ORDER: Array[String] = ["low", "mid", "high"]
const PRESET_LABELS: Array[String] = ["自动", "低", "中", "高", "自定义"]

var _values: Dictionary = {}
var _config := ConfigFile.new()
var _dynamic_timer: float = 0.0
var _low_samples: int = 0
var _high_samples: int = 0


func _ready() -> void:
	_load()
	apply_all()


func _process(delta: float) -> void:
	if not bool(get_value("graphics/dynamic_resolution")):
		return
	_dynamic_timer += delta
	if _dynamic_timer < 1.0:
		return
	_dynamic_timer = 0.0

	var target: int = int(get_value("graphics/fps_cap"))
	if target <= 0:
		target = 60
	var base: float = float(get_value("graphics/render_scale"))
	var viewport := get_viewport()
	if viewport == null:
		return
	var current: float = viewport.scaling_3d_scale
	var fps: float = Engine.get_frames_per_second()

	if fps > 0.0 and fps < float(target) * 0.90:
		_low_samples += 1
		_high_samples = 0
	else:
		_high_samples += 1
		_low_samples = 0

	if _low_samples >= 2 and current > 0.5:
		viewport.scaling_3d_scale = maxf(0.5, current - 0.05)
		_low_samples = 0
	elif _high_samples >= 3 and current < base:
		viewport.scaling_3d_scale = minf(base, current + 0.05)
		_high_samples = 0


func get_value(key: String, default_value: Variant = null) -> Variant:
	if _values.has(key):
		return _values[key]
	var high: Dictionary = PRESETS["high"]
	if high.has(key):
		return high[key]
	return default_value


func set_value(key: String, value: Variant, mark_custom: bool = true) -> void:
	if _values.has(key) and _values[key] == value:
		return
	_values[key] = value
	if mark_custom and key != "graphics/preset":
		_values["graphics/preset"] = "custom"
	_apply_key(key)
	_save()
	changed.emit(key, value)


func set_preset(preset: String) -> void:
	if preset == "custom":
		return
	var resolved := preset
	if resolved == "auto":
		resolved = detect_tier()
	if not PRESETS.has(resolved):
		return
	var values: Dictionary = PRESETS[resolved]
	for key: String in values:
		_values[key] = values[key]
	_values["graphics/preset"] = preset
	apply_all()
	_save()
	changed.emit("graphics/preset", preset)


func reset_to_defaults() -> void:
	_apply_preset_values("auto")
	apply_all()
	_save()
	changed.emit("graphics/preset", "auto")


func get_preset() -> String:
	return String(_values.get("graphics/preset", "auto"))


func detect_tier() -> String:
	var model := OS.get_model_name()
	if model.begins_with("iPhone"):
		var head: String = model.split(",")[0]
		var major := int(head.replace("iPhone", ""))
		if major >= 15:
			return "high"
		if major >= 13:
			return "mid"
		return "low"
	var adapter := RenderingServer.get_video_adapter_name().to_lower()
	if adapter.contains("apple"):
		return "high"
	return "mid"


func apply_all() -> void:
	for key: String in _values.keys():
		_apply_key(key)


func _apply_key(key: String) -> void:
	var viewport := get_viewport()
	match key:
		"graphics/render_scale":
			if viewport:
				viewport.scaling_3d_scale = float(_values.get(key, 0.85))
		"graphics/fps_cap":
			Engine.max_fps = int(_values.get(key, 60))
		"graphics/shadows":
			var quality := String(_values.get(key, "high"))
			var enabled := quality != "off"
			var distance := 45.0 if quality == "high" else 22.0
			for node in get_tree().get_nodes_in_group("sun"):
				if node is DirectionalLight3D:
					node.shadow_enabled = enabled
					node.directional_shadow_max_distance = distance
		"graphics/fx_intensity":
			var intensity := float(_values.get(key, 1.0))
			for node in get_tree().get_nodes_in_group("fx"):
				if node is GPUParticles3D:
					node.amount_ratio = intensity
		"graphics/post":
			var on := bool(_values.get(key, true))
			for node in get_tree().get_nodes_in_group("world_env"):
				if node is WorldEnvironment and node.environment:
					node.environment.glow_enabled = on
		"graphics/msaa":
			if viewport:
				viewport.msaa_3d = Viewport.MSAA_2X if String(_values.get(key, "off")) == "2x" else Viewport.MSAA_DISABLED


func _load() -> void:
	var err := _config.load(CONFIG_PATH)
	if err != OK:
		_apply_preset_values("auto")
		_save()
		return
	_values.clear()
	if _config.has_section("graphics"):
		for key in _config.get_section_keys("graphics"):
			_values["graphics/" + key] = _config.get_value("graphics", key)
	if not _values.has("graphics/preset"):
		_apply_preset_values("auto")
		_save()
	elif String(_values["graphics/preset"]) == "auto":
		_apply_preset_values("auto")
		_save()


func _apply_preset_values(preset: String) -> void:
	var resolved := preset
	if resolved == "auto":
		resolved = detect_tier()
	if not PRESETS.has(resolved):
		resolved = "mid"
	var values: Dictionary = PRESETS[resolved]
	for key: String in values:
		_values[key] = values[key]
	_values["graphics/preset"] = preset


func _save() -> void:
	for key: String in _values.keys():
		if key.begins_with("graphics/"):
			_config.set_value("graphics", key.trim_prefix("graphics/"), _values[key])
	_config.save(CONFIG_PATH)

