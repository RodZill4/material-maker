tool
extends ViewportContainer

const MODE_FREE       = 0
const MODE_LINE       = 1
const MODE_LINE_STRIP = 2

var mode = MODE_FREE

var brush_size     = 50.0
var brush_strength = 0.5
var texture_albedo = null
var texture_mr     = null
var texture_normal = null
var texture_scale = 2.0

var previous_position = null
var painting = false
var next_paint_to = null

var object_name = null

onready var albedo_viewport = $AlbedoPaint/Viewport
onready var mr_viewport = $MRPaint/Viewport
onready var normal_viewport = $NormalPaint/Viewport
onready var albedo_material = $AlbedoPaint/Viewport/ColorRect.get_material()
onready var mr_material = $MRPaint/Viewport/ColorRect.get_material()
onready var normal_material = $NormalPaint/Viewport/ColorRect.get_material()

onready var brush_material = $Brush.get_material()

const MATERIAL_OPTIONS = [ "none", "bricks", "metal_pattern", "rusted_metal", "wooden_floor" ]

signal update_material

func _ready():
	# add View2Texture as input of Texture2View (to ignore non-visible parts of the mesh)
	$Texture2View/Viewport/PaintedMesh.get_surface_material(0).set_shader_param("view2texture", $View2Texture/Viewport.get_texture())
	# Add Texture2View as input to all painted textures
	$FixSeams/Viewport.get_texture().flags |= Texture.FLAG_FILTER
	albedo_material.set_shader_param("tex2view_tex", $FixSeams/Viewport.get_texture())
	mr_material.set_shader_param("tex2view_tex", $FixSeams/Viewport.get_texture())
	normal_material.set_shader_param("tex2view_tex", $FixSeams/Viewport.get_texture())
	# Add all painted textures as input to themselves
	albedo_material.set_shader_param("self_tex", albedo_viewport.get_texture())
	mr_material.set_shader_param("self_tex", mr_viewport.get_texture())
	normal_material.set_shader_param("self_tex", normal_viewport.get_texture())
	# Assign all textures to painted mesh
	albedo_viewport.get_texture().flags |= Texture.FLAG_FILTER
	$Viewport/PaintedMesh.get_surface_material(0).albedo_texture = albedo_viewport.get_texture()
	mr_viewport.get_texture().flags |= Texture.FLAG_FILTER
	$Viewport/PaintedMesh.get_surface_material(0).metallic_texture = mr_viewport.get_texture()
	$Viewport/PaintedMesh.get_surface_material(0).roughness_texture = mr_viewport.get_texture()
	normal_viewport.get_texture().flags |= Texture.FLAG_FILTER
	$Viewport/PaintedMesh.get_surface_material(0).normal_texture = normal_viewport.get_texture()
	# Updated Texture2View wrt current camera position
	update_tex2view()
	# Set size of painted textures
	set_texture_size(2048)
	# update the material list
	$Material/OptionButton.clear()
	for m in MATERIAL_OPTIONS:
		$Material/OptionButton.add_item(m)
	select_material(0)
	# Initialize brush related parameters in paint shaders
	update_brush_parameters()

func set_mesh(n, m):
	object_name = n
	var mat
	mat = $Viewport/PaintedMesh.get_surface_material(0)
	$Viewport/PaintedMesh.mesh = m
	$Viewport/PaintedMesh.set_surface_material(0, mat)
	mat = $Texture2View/Viewport/PaintedMesh.get_surface_material(0)
	$Texture2View/Viewport/PaintedMesh.mesh = m
	$Texture2View/Viewport/PaintedMesh.set_surface_material(0, mat)
	mat = $View2Texture/Viewport/PaintedMesh.get_surface_material(0)
	$View2Texture/Viewport/PaintedMesh.mesh = m
	$View2Texture/Viewport/PaintedMesh.set_surface_material(0, mat)
	update_tex2view()
	save()

func set_mode(m):
	mode = m
	for i in $Tools.get_child_count():
		$Tools.get_child(i).pressed = (i == m)

func set_texture_size(s):
	$Texture2View/Viewport.size = Vector2(s, s)
	$FixSeams/Viewport.size = Vector2(s, s)
	$FixSeams/Viewport/TextureRect1.rect_size = Vector2(s, s)
	$FixSeams/Viewport/TextureRect2.rect_size = Vector2(s, s)
	$FixSeams/Viewport/TextureRect3.rect_size = Vector2(s, s)
	$FixSeams/Viewport/TextureRect4.rect_size = Vector2(s, s)
	$FixSeams/Viewport/TextureRect5.rect_size = Vector2(s, s)
	$AlbedoPaint/Viewport.size = Vector2(s, s)
	$AlbedoPaint/Viewport/ColorRect.rect_size = Vector2(s, s)
	$MRPaint/Viewport.size = Vector2(s, s)
	$MRPaint/Viewport/ColorRect.rect_size = Vector2(s, s)

func _on_Test_gui_input(ev):
	if ev is InputEventWithModifiers:
		if ev.control:
			$Texture.show()
		else:
			$Texture.hide()
	if ev is InputEventMouseMotion:
		show_brush(ev.position, previous_position)
		if ev.button_mask & BUTTON_MASK_RIGHT != 0:
			$Viewport/CameraStand.rotate_y(-0.01*ev.relative.x)
			$Viewport/CameraStand.rotate_x(-0.01*ev.relative.y)
		if ev.button_mask & BUTTON_MASK_LEFT != 0:
			if ev.control:
				previous_position = null
				texture_scale += ev.relative.x*0.1
				texture_scale = clamp(texture_scale, 0.01, 20.0)
			elif ev.shift:
				previous_position = null
				brush_size += ev.relative.x*0.1
				brush_size = clamp(brush_size, 0.0, 250.0)
				brush_strength += ev.relative.y*0.01
				brush_strength = clamp(brush_strength, 0.0, 0.999)
				update_brush_parameters()
			elif mode == MODE_FREE:
				paint(ev.position)
		elif mode != MODE_LINE_STRIP:
			previous_position = null
	elif ev is InputEventMouseButton and !ev.shift:
		var pos = ev.position
		if ev.pressed:
			var zoom = 0.0
			if ev.button_index == BUTTON_WHEEL_UP:
				zoom += 0.1
				$Viewport/CameraStand/Camera.translate(Vector3(0.0, 0.0, zoom))
				update_tex2view()
			elif ev.button_index == BUTTON_WHEEL_DOWN:
				zoom -= 0.1
				$Viewport/CameraStand/Camera.translate(Vector3(0.0, 0.0, zoom))
				update_tex2view()
			elif ev.button_index == BUTTON_LEFT:
				if mode == MODE_LINE_STRIP && previous_position != null:
					paint(pos)
					if ev.doubleclick:
						pos = null
				previous_position = pos
		else:
			if ev.button_index == BUTTON_RIGHT:
				update_tex2view()
			elif ev.button_index == BUTTON_LEFT:
				if mode != MODE_LINE_STRIP:
					paint(pos)
					previous_position = null

func show_brush(p, op = null):
	if op == null:
		op = p
	var position = p/rect_size
	var old_position = op/rect_size
	brush_material.set_shader_param("brush_pos", position)
	brush_material.set_shader_param("brush_ppos", old_position)

func update_brush_parameters():
	var brush_size_vector = Vector2(brush_size, brush_size)/rect_size
	if brush_material != null:
		brush_material.set_shader_param("brush_size", Vector2(brush_size, brush_size)/rect_size)
		brush_material.set_shader_param("brush_strength", brush_strength)
	if albedo_material != null:
		albedo_material.set_shader_param("brush_size", brush_size_vector)
		albedo_material.set_shader_param("brush_strength", brush_strength)
	if mr_material != null:
		mr_material.set_shader_param("brush_size", brush_size_vector)
		mr_material.set_shader_param("brush_strength", brush_strength)
	if normal_material != null:
		normal_material.set_shader_param("brush_size", brush_size_vector)
		normal_material.set_shader_param("brush_strength", brush_strength)

func paint(p):
	if painting:
		# if not available for painting, record a paint order
		next_paint_to = p
		return
	painting = true
	if previous_position == null:
		previous_position = p
	var position = p/rect_size
	var prev_position = previous_position/rect_size
	albedo_material.set_shader_param("brush_pos", position)
	albedo_material.set_shader_param("brush_ppos", prev_position)
	albedo_material.set_shader_param("brush_color", $Material/AlbedoColor.color)
	albedo_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	albedo_viewport.update_worlds()
	mr_material.set_shader_param("brush_pos", position)
	mr_material.set_shader_param("brush_ppos", prev_position)
	mr_material.set_shader_param("brush_color", $Material/MRColor.color)
	mr_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	mr_viewport.update_worlds()
	normal_material.set_shader_param("brush_pos", position)
	normal_material.set_shader_param("brush_ppos", prev_position)
	normal_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	normal_viewport.update_worlds()
	previous_position = p
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	painting = false
	# execute recorded paint order if any
	if next_paint_to != null:
		p = next_paint_to
		next_paint_to = null
		paint(p)

func update_tex2view():
	var camera = $Viewport/CameraStand/Camera
	var transform = camera.global_transform.affine_inverse()*$Viewport/PaintedMesh.global_transform
	# View to texture
	$View2Texture/Viewport.size = $Viewport.size
	$View2Texture/Viewport/Camera.transform = camera.global_transform
	$View2Texture/Viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	$View2Texture/Viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	var t2v_shader_material = $Texture2View/Viewport/PaintedMesh.get_surface_material(0)
	t2v_shader_material.set_shader_param("model_transform", transform)
	t2v_shader_material.set_shader_param("fovy_degrees", camera.fov)
	t2v_shader_material.set_shader_param("z_near", camera.near)
	t2v_shader_material.set_shader_param("z_far", camera.far)
	t2v_shader_material.set_shader_param("aspect", rect_size.x/rect_size.y)
	$Texture2View/Viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	$Texture2View/Viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$Texture2View/Viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	$FixSeams/Viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	$FixSeams/Viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$FixSeams/Viewport.render_target_update_mode = Viewport.UPDATE_DISABLED

func load_material():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.paintmat;Paint material")
	dialog.connect("file_selected", self, "do_load_material")
	dialog.popup_centered()

func do_load_material(filename):
	pass

func select_material(id):
	var m = $Material/OptionButton.get_item_text(id)
	if m == "none":
		texture_albedo = null
		texture_mr     = null
		texture_normal = null
	else:
		texture_albedo = load("res://addons/procedural_material/paint_tool/materials/%s_albedo.png" % m)
		texture_mr     = load("res://addons/procedural_material/paint_tool/materials/%s_mr.png" % m)
		texture_normal = load("res://addons/procedural_material/paint_tool/materials/%s_normal_map.png" % m)
	albedo_material.set_shader_param("brush_texture", texture_albedo)
	mr_material.set_shader_param("brush_texture", texture_mr)
	normal_material.set_shader_param("brush_texture", texture_normal)

func _on_resized():
	update_brush_parameters()

func dump_viewport(viewport, filename):
	var viewport_texture = viewport.get_texture()
	var viewport_image = viewport_texture.get_data()
	viewport_image.save_png(filename)

func debug():
	dump_viewport($View2Texture/Viewport, "view2texture.png")
	dump_viewport($Texture2View/Viewport, "texture2view.png")
	dump_viewport($FixSeams/Viewport, "seamsfixed.png")

func save():
	var mat = $Viewport/PaintedMesh.get_surface_material(0).duplicate()
	dump_viewport($AlbedoPaint/Viewport, object_name+"_albedo.png")
	dump_viewport($MRPaint/Viewport, object_name+"_mr.png")
	dump_viewport($NormalPaint/Viewport, object_name+"_nm.png")
	emit_signal("update_material", { material=mat, albedo=object_name+"_albedo.png", mr=object_name+"_mr.png", nm=object_name+"_nm.png" })

