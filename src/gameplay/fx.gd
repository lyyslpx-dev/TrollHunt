class_name FX
extends RefCounted
## 占位特效。全部走加色面片，方便后面替换成正式美术。


static func slash(parent: Node, world_position: Vector3, color: Color = Color(1.0, 0.95, 0.75)) -> void:
	var mesh := _arc_mesh(0.45, 1.05, -1.05, 1.05, 18)
	var material := _additive_material(color)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = world_position + Vector3(0, 0.9, 0)
	instance.rotation.z = randf_range(-0.6, 0.6)
	instance.scale = Vector3(0.7, 0.7, 0.7)
	parent.add_child(instance)
	var tween := instance.create_tween()
	tween.tween_property(instance, "scale", Vector3(1.5, 1.5, 1.5), 0.18)
	tween.parallel().tween_property(material, "albedo_color", Color(color.r, color.g, color.b, 0.0), 0.18)
	tween.tween_callback(instance.queue_free)


static func aoe(parent: Node, world_position: Vector3, radius: float, color: Color = Color(1.0, 0.5, 0.1)) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.05
	mesh.radial_segments = 32
	var material := _additive_material(Color(color.r, color.g, color.b, 0.32))
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = world_position + Vector3(0, 0.06, 0)
	parent.add_child(instance)
	instance.scale = Vector3(0.35, 1.0, 0.35)
	var tween := instance.create_tween()
	tween.tween_property(instance, "scale", Vector3(1.0, 1.0, 1.0), 0.28)
	tween.parallel().tween_property(material, "albedo_color", Color(color.r, color.g, color.b, 0.0), 0.4)
	tween.tween_callback(instance.queue_free)


static func pillar(parent: Node, world_position: Vector3, color: Color, height: float = 6.0) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.35
	mesh.bottom_radius = 0.55
	mesh.height = height
	mesh.radial_segments = 16
	var material := _additive_material(Color(color.r, color.g, color.b, 0.55))
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = world_position + Vector3(0, height * 0.5, 0)
	parent.add_child(instance)
	var tween := instance.create_tween()
	tween.tween_property(material, "albedo_color", Color(color.r, color.g, color.b, 0.0), 0.55)
	tween.parallel().tween_property(instance, "scale", Vector3(0.2, 1.0, 0.2), 0.55)
	tween.tween_callback(instance.queue_free)


static func _additive_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true
	return material


static func _arc_mesh(inner: float, outer: float, start_angle: float, end_angle: float, segments: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segments:
		var a0 := lerpf(start_angle, end_angle, float(i) / float(segments))
		var a1 := lerpf(start_angle, end_angle, float(i + 1) / float(segments))
		var inner0 := Vector3(cos(a0) * inner, sin(a0) * inner, 0.0)
		var outer0 := Vector3(cos(a0) * outer, sin(a0) * outer, 0.0)
		var inner1 := Vector3(cos(a1) * inner, sin(a1) * inner, 0.0)
		var outer1 := Vector3(cos(a1) * outer, sin(a1) * outer, 0.0)
		surface.add_vertex(inner0)
		surface.add_vertex(outer0)
		surface.add_vertex(outer1)
		surface.add_vertex(inner0)
		surface.add_vertex(outer1)
		surface.add_vertex(inner1)
	surface.generate_normals()
	return surface.commit()


static func whirlwind(parent: Node, world_position: Vector3, radius: float, color: Color) -> void:
	for i in 6:
		var mesh := _arc_mesh(radius * 0.25, radius, float(i) / 6.0 * TAU, float(i) / 6.0 * TAU + 0.8, 12)
		var material := _additive_material(Color(color.r, color.g, color.b, 0.7))
		material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		instance.material_override = material
		instance.position = world_position + Vector3(0, 0.15, 0)
		instance.rotation.y = randf_range(0.0, TAU)
		parent.add_child(instance)
		var tween := instance.create_tween()
		tween.tween_property(instance, "rotation:y", instance.rotation.y + 2.2, 0.4)
		tween.parallel().tween_property(instance, "scale", Vector3(1.7, 1.7, 1.7), 0.4)
		tween.parallel().tween_property(material, "albedo_color", Color(color.r, color.g, color.b, 0.0), 0.4)
		tween.tween_callback(instance.queue_free)
	aoe(parent, world_position, radius, color)


static func ring(parent: Node, world_position: Vector3, radius: float, color: Color) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.4
	torus.outer_radius = radius * 0.52
	var material := _additive_material(Color(color.r, color.g, color.b, 0.85))
	var instance := MeshInstance3D.new()
	instance.mesh = torus
	instance.material_override = material
	instance.position = world_position + Vector3(0, 0.1, 0)
	parent.add_child(instance)
	var tween := instance.create_tween()
	tween.tween_property(instance, "scale", Vector3(1.9, 1.9, 1.9), 0.35)
	tween.parallel().tween_property(material, "albedo_color", Color(color.r, color.g, color.b, 0.0), 0.4)
	tween.tween_callback(instance.queue_free)


static func thunder(parent: Node, world_position: Vector3, color: Color) -> void:
	pillar(parent, world_position, color, 8.0)
	ring(parent, world_position, 3.2, color)
	for i in 5:
		var bolt := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.06
		mesh.bottom_radius = 0.06
		mesh.height = randf_range(2.0, 4.0)
		bolt.mesh = mesh
		var mat := _additive_material(Color(color.r, color.g, color.b, 0.9))
		bolt.material_override = mat
		var offset := Vector3(randf_range(-1.5, 1.5), 3.5, randf_range(-1.5, 1.5))
		bolt.position = world_position + offset
		bolt.rotation.x = randf_range(-0.5, 0.5)
		bolt.rotation.z = randf_range(-0.5, 0.5)
		parent.add_child(bolt)
		var btween := bolt.create_tween()
		btween.tween_property(mat, "albedo_color", Color(color.r, color.g, color.b, 0.0), 0.3)
		btween.tween_callback(bolt.queue_free)


static func sparks(parent: Node, world_position: Vector3, color: Color, count: int = 10) -> void:
	for i in count:
		var spark := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.06
		mesh.height = 0.12
		spark.mesh = mesh
		var material := _additive_material(Color(color.r, color.g, color.b, 0.9))
		spark.material_override = material
		spark.position = world_position + Vector3(0, 0.5, 0)
		parent.add_child(spark)
		var direction := Vector3(randf_range(-1, 1), randf_range(0.3, 1), randf_range(-1, 1)).normalized()
		var tween := spark.create_tween()
		tween.tween_property(spark, "position", spark.position + direction * randf_range(1.5, 3.0), 0.35).set_trans(Tween.TRANS_QUAD)
		tween.parallel().tween_property(material, "albedo_color", Color(color.r, color.g, color.b, 0.0), 0.35)
		tween.tween_callback(spark.queue_free)


static func dash(parent: Node, from: Vector3, to: Vector3, color: Color) -> void:
	for i in 6:
		var ghost := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.4
		mesh.height = 1.4
		ghost.mesh = mesh
		var material := _additive_material(Color(color.r, color.g, color.b, 0.25))
		ghost.material_override = material
		var t := float(i) / 5.0
		ghost.position = from.lerp(to, t) + Vector3(0, 0.7, 0)
		parent.add_child(ghost)
		var tween := ghost.create_tween()
		tween.tween_property(material, "albedo_color", Color(color.r, color.g, color.b, 0.0), 0.3)
		tween.tween_callback(ghost.queue_free)

