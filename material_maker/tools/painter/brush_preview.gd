extends Node


const DEBUG : bool = true


export var background_material : Material

var initialized = false
onready var painter = $Painter
onready var camera = $Viewport/Camera


func set_brush(brush) -> Texture:
	if !initialized:
		var preview_material : SpatialMaterial = SpatialMaterial.new()
		preview_material.albedo_texture = painter.get_albedo_texture()
		preview_material.albedo_texture.flags = Texture.FLAGS_DEFAULT
		preview_material.metallic = 1.0
		preview_material.metallic_texture = painter.get_mr_texture()
		preview_material.metallic_texture.flags = Texture.FLAGS_DEFAULT
		preview_material.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
		preview_material.roughness = 1.0
		preview_material.roughness_texture = painter.get_mr_texture()
		preview_material.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN
		preview_material.emission_enabled = true
		preview_material.emission = Color(0.0, 0.0, 0.0, 0.0)
		preview_material.emission_texture = painter.get_emission_texture()
		preview_material.emission_texture.flags = Texture.FLAGS_DEFAULT
		preview_material.normal_enabled = true
		$NormalMap/Rect.material.set_shader_param("epsilon", 1.0/512.0)
		# TODO: Fix this
		#$NormalMap/Rect.material.set_shader_param("tex", painter.get_depth_texture())
		preview_material.normal_texture = $NormalMap.get_texture()
		preview_material.normal_texture.flags = Texture.FLAGS_DEFAULT
		preview_material.depth_enabled = true
		preview_material.depth_deep_parallax = true
		# TODO: Fix this
		#preview_material.depth_texture = painter.get_depth_texture()
		#preview_material.depth_texture.flags = Texture.FLAGS_DEFAULT
		$Viewport/Object.set_surface_material(0, preview_material)
		var result = painter.set_mesh($Viewport/Object.mesh)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		var mesh_instance = $Viewport/Object
		var mesh_aabb = mesh_instance.get_aabb()
		var mesh_center = mesh_aabb.position+0.5*mesh_aabb.size
		var mesh_size = 0.5*mesh_aabb.size.length()
		var cam_to_center = (camera.global_transform.origin-mesh_center).length()
		camera.near = max(0.2, 0.5*(cam_to_center-mesh_size))
		camera.far = 2.0*(cam_to_center+mesh_size)
		var transform = camera.global_transform.affine_inverse()*mesh_instance.global_transform
		painter.update_view(camera, transform, $Viewport.size)
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
	painter.set_texture_size(1024)
	painter.set_brush_node(brush)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	painter.init_textures(background_material)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	var paint_parameters : Dictionary = {
		texture_space=false,
		rect_size=Vector2(512, 512),
		texture_center=Vector2(0.5, 0.5),
		texture_scale=1.0,
		brush_pos=Vector2(256, 256),
		brush_ppos=Vector2(256, 256),
		brush_size=256,
		brush_opacity=1.0,
		brush_hardness=0.8,
		stroke_length=100.0,
		stroke_angle=0.0,
		erase=false,
		pressure=1.0,
		fill=false
	}
	painter.paint(paint_parameters, true)
	yield(painter, "end_of_stroke")
	painter.paint(paint_parameters, true)
	yield(painter, "end_of_stroke")
	$NormalMap.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	if DEBUG:
		for i in painter.debug_get_texture_names().size():
			var t = painter.debug_get_texture(i)
			t.get_data().save_png("d:/debug_brush_preview_%d.png" % i)
	initialized = true
	return $Viewport.get_texture()
