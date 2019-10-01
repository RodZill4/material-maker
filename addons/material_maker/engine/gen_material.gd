tool
extends MMGenBase
class_name MMGenMaterial

var texture_list

var material : SpatialMaterial
var generated_textures = {}

const TEXTURE_LIST = [
	{ port=0, texture="albedo" },
	{ port=1, texture="metallic" },
	{ port=2, texture="roughness" },
	{ port=3, texture="emission" },
	{ port=4, texture="normal_texture" },
	{ port=5, texture="ao_texture" },
	{ port=6, texture="depth_texture" }
]

const ADDON_TEXTURE_LIST = [
	{ port=0, texture="albedo" },
	{ port=3, texture="emission" },
	{ port=4, texture="normal_texture" },
	{ ports=[5, 1, 2], default_values=["1.0", "0.0", "1.0"], texture="orm" },
	{ port=6, texture="depth_texture" }
]

func _ready():
	texture_list = TEXTURE_LIST
	for t in texture_list:
		generated_textures[t.texture] = null
	material = SpatialMaterial.new()

func get_type():
	return "material"

func get_type_name():
	return "Material"

func get_parameter_defs():
	return [
		{ name="albedo_color", label="Albedo", type="color", default={ r=1.0, g=1.0, b=1.0, a=1.0} },
		{ name="metallic", label="Metallic", type="float", min=0.0, max=1.0, step=0.05, default=1.0 },
		{ name="roughness", label="Roughness", type="float", min=0.0, max=1.0, step=0.05, default=1.0 },
		{ name="emission_energy", label="Emission", type="float", min=0.0, max=8.0, step=0.05, default=1.0 },
		{ name="normal_scale", label="Normal", type="float", min=0.0, max=8.0, step=0.05, default=1.0 },
		{ name="ao_light_affect", label="Ambient occlusion", type="float", min=0.0, max=1.0, step=0.05, default=1.0 },
		{ name="depth_scale", label="Depth", type="float", min=0.0, max=1.0, step=0.05, default=1.0 }
	]

func get_input_defs():
	return [
		{ name="albedo_texture", label="", type="rgb" },
		{ name="metallic_texture", label="", type="f" },
		{ name="roughness_texture", label="", type="f" },
		{ name="emission_texture", label="", type="rgb" },
		{ name="normal_texture", label="", type="rgb" },
		{ name="ao_texture", label="", type="f" },
		{ name="depth_texture", label="", type="f" }
	]

func source_changed(input_index : int):
	emit_signal("update_textures")

func render_textures(renderer : MMGenRenderer):
	for t in texture_list:
		if t.has("port"):
			var source = get_source(t.port)
			var texture = null
			if source != null:
				var status = source.generator.render(source.output_index, renderer, 1024)
				while status is GDScriptFunctionState:
					status = yield(status, "completed")
				texture = ImageTexture.new()
				texture.create_from_image(renderer.get_texture().get_data())
			generated_textures[t.texture] = texture

func update_materials(material_list):
	for m in material_list:
		update_spatial_material(m)

func get_generated_texture(slot, file_prefix = null):
	if file_prefix != null:
		var file_name = "%s_%s.png" % [ file_prefix, slot ]
		if File.new().file_exists(file_name):
			return load(file_name)
		else:
			return null
	else:
		return generated_textures[slot]

func update_spatial_material(m, file_prefix = null):
	var texture
	m.albedo_color = parameters.albedo_color
	m.albedo_texture = get_generated_texture("albedo", file_prefix)
	m.metallic = parameters.metallic
	m.roughness = parameters.roughness
	if false:
		texture = get_generated_texture("mrao", file_prefix)
		m.metallic_texture = texture 
		m.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
		m.roughness_texture = texture
		m.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN
	else:
		m.metallic_texture = get_generated_texture("metallic", file_prefix)
		m.roughness_texture = get_generated_texture("roughness", file_prefix)
	texture = get_generated_texture("emission", file_prefix)
	if texture != null:
		m.emission_enabled = true
		m.emission_energy = parameters.emission_energy
		m.emission_texture = texture
	else:
		m.emission_enabled = false
	texture = get_generated_texture("normal_texture", file_prefix)
	if texture != null:
		m.normal_enabled = true
		m.normal_texture = texture
	else:
		m.normal_enabled = false
	if false:
		if (generated_textures.mrao.mask & (1 << 2)) != 0:
			m.ao_enabled = true
			m.ao_light_affect = parameters.ao_light_affect
			m.ao_texture = m.metallic_texture
			m.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_BLUE
		else:
			m.ao_enabled = false
	else:
		texture = get_generated_texture("ao_texture", file_prefix)
		if texture != null:
			m.ao_enabled = true
			m.ao_light_affect = parameters.ao_light_affect
			m.ao_texture = texture
		else:
			m.ao_enabled = false
	texture = get_generated_texture("depth_texture", file_prefix)
	if texture != null:
		m.depth_enabled = true
		m.depth_deep_parallax = true
		m.depth_scale = parameters.depth_scale * 0.2
		m.depth_texture = texture
	else:
		m.depth_enabled = false

func export_textures(prefix, editor_interface = null):
	for t in texture_list:
		var texture = generated_textures[t.texture]
		if texture != null:
			var image = texture.get_data()
			image.save_png("%s_%s.png" % [ prefix, t.texture ])
	if Engine.editor_hint:
		var resource_filesystem = editor_interface.get_resource_filesystem()
		resource_filesystem.scan()
		yield(resource_filesystem, "filesystem_changed")
		var new_material = SpatialMaterial.new()
		update_spatial_material(new_material, prefix)
		ResourceSaver.save("%s.tres" % [ prefix ], new_material)
		resource_filesystem.scan()
		return new_material

func _serialize(data):
	return data
