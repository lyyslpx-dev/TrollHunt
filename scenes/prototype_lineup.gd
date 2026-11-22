extends Node3D


func _ready() -> void:
	var clay := StandardMaterial3D.new()
	clay.albedo_color = Color(0.62, 0.61, 0.59, 1)
	clay.roughness = 0.95
	clay.metallic = 0.0
	for name in ["Warrior", "Mage", "Taoist"]:
		var model := get_node_or_null(name)
		if model == null:
			continue
		for node in model.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			if mesh:
				mesh.material_override = clay

	for _frame in 45:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("user://prototype_lineup.png")
	print("[prototype] screenshot: ", ProjectSettings.globalize_path("user://prototype_lineup.png"))
	get_tree().quit()
