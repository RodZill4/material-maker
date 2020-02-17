tool
extends MMGenShader
class_name MMGenMaterial

var material : SpatialMaterial
var generated_textures = {}

const TEXTURE_LIST = [
	{ port=0, texture="albedo" },
	{ port=1, texture="orm" },
	{ port=2, texture="emission" },
	{ port=3, texture="normal" },
	{ port=4, texture="depth" },
	{ port=5, texture="sss" }
]

const INPUT_ALBEDO    : int = 0
const INPUT_METALLIC  : int = 1
const INPUT_ROUGHNESS : int = 2
const INPUT_EMISSION  : int = 3
const INPUT_NORMAL    : int = 4
const INPUT_OCCLUSION : int = 5
const INPUT_DEPTH     : int = 6
const INPUT_SSS       : int = 7

# The minimum allowed texture size as a power-of-two exponent
const TEXTURE_SIZE_MIN = 4  # 16x16

# The maximum allowed texture size as a power-of-two exponent
const TEXTURE_SIZE_MAX = 12  # 4096x4096

# The default texture size as a power-of-two exponent
const TEXTURE_SIZE_DEFAULT = 10  # 1024x1024


func _ready() -> void:
	for t in TEXTURE_LIST:
		generated_textures[t.texture] = null
	material = SpatialMaterial.new()

func can_be_deleted() -> bool:
	return false

func get_type() -> String:
	return "material"

func get_type_name() -> String:
	return "Material"

func get_output_defs__() -> Array:
	return []

func get_image_size() -> int:
	var rv : int
	if parameters.has("size"):
		rv = int(pow(2, parameters.size))
	else:
		rv = int(pow(2, TEXTURE_SIZE_DEFAULT))
	return rv

func update_preview() -> void:
	var graph_edit = self
	while graph_edit is MMGenBase:
		graph_edit = graph_edit.get_parent()
	if graph_edit != null and graph_edit.has_method("send_changed_signal"):
		graph_edit.send_changed_signal()

func set_parameter(p, v) -> void:
	.set_parameter(p, v)
	update_preview()

func source_changed(input_index : int) -> void:
	for t in TEXTURE_LIST:
		if t.has("port") and t.port == input_index:
			generated_textures[t.texture] = null
		elif t.has("ports") and t.ports.has(input_index):
			generated_textures[t.texture] = null
	update_preview()

func render_textures() -> void:
	for t in TEXTURE_LIST:
		var texture = null
		var result
		if t.has("port"):
			if generated_textures[t.texture] != null:
				continue
			result = render(t.port, get_image_size())
		else:
			generated_textures[t.texture] = null
			continue
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		texture = ImageTexture.new()
		result.copy_to_texture(texture)
		result.release()
		# To work, this must be set after calling `copy_to_texture()`
		texture.flags |= ImageTexture.FLAG_ANISOTROPIC_FILTER

		# Disable filtering for small textures, as they're considered to be used
		# for a pixel art style
		if texture.get_size().x <= 128:
			texture.flags ^= ImageTexture.FLAG_FILTER

		generated_textures[t.texture] = texture

func update_materials(material_list) -> void:
	for m in material_list:
		update_material(m)

func get_generated_texture(slot, file_prefix = null) -> ImageTexture:
	if file_prefix != null:
		var file_name = "%s_%s.png" % [ file_prefix, slot ]
		if File.new().file_exists(file_name):
			var texture = load(file_name)
			return texture
		else:
			return null
	else:
		return generated_textures[slot]

func update_material(m, file_prefix = null) -> void:
	var texture
	if m is SpatialMaterial:
		# Make the material double-sided for better visiblity in the preview
		m.params_cull_mode = SpatialMaterial.CULL_DISABLED
		# Albedo
		m.albedo_color = parameters.albedo
		m.albedo_texture = get_generated_texture("albedo", file_prefix)
		# Ambient occlusion
		if get_source(INPUT_OCCLUSION) != null:
			m.ao_enabled = true
			m.ao_light_affect = parameters.ao
			m.ao_texture = get_generated_texture("orm", file_prefix)
			m.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
		else:
			m.ao_enabled = false
		# Roughness
		m.roughness = parameters.roughness
		if get_source(INPUT_ROUGHNESS) != null:
			m.roughness_texture = get_generated_texture("orm", file_prefix)
			m.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN
		else:
			m.roughness_texture = null
		# Metallic
		m.metallic = parameters.metallic
		if get_source(INPUT_ROUGHNESS) != null:
			m.metallic_texture = get_generated_texture("orm", file_prefix)
			m.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_BLUE
		else:
			m.metallic_texture = null
		# Emission
		if get_source(INPUT_EMISSION) != null:
			m.emission_enabled = true
			m.emission_energy = parameters.emission
			m.emission_texture = get_generated_texture("emission", file_prefix)
		else:
			m.emission_enabled = false
		# Normal map
		if get_source(INPUT_NORMAL) != null:
			m.normal_enabled = true
			m.normal_texture = get_generated_texture("normal", file_prefix)
		else:
			m.normal_enabled = false
		# Depth
		if get_source(INPUT_DEPTH) != null and parameters.depth > 0:
			m.depth_enabled = true
			m.depth_deep_parallax = true
			m.depth_scale = parameters.depth * 0.2
			m.depth_texture = get_generated_texture("depth", file_prefix)
		else:
			m.depth_enabled = false
		# Subsurface scattering
		if get_source(INPUT_SSS) != null:
			m.subsurf_scatter_enabled = true
			m.subsurf_scatter_strength = parameters.sss
			m.subsurf_scatter_texture = get_generated_texture("sss", file_prefix)
		else:
			m.subsurf_scatter_enabled = false
	else:
		m.set_shader_param("albedo", parameters.albedo_color)
		m.set_shader_param("texture_albedo", get_generated_texture("albedo", file_prefix))
		m.set_shader_param("metallic", parameters.metallic)
		m.set_shader_param("texture_metallic", get_generated_texture("orm", file_prefix))
		m.set_shader_param("metallic_texture_channel", PoolRealArray([0.0, 0.0, 1.0, 0.0]))
		m.set_shader_param("roughness", parameters.roughness)
		m.set_shader_param("texture_roughness", get_generated_texture("orm", file_prefix))
		m.set_shader_param("roughness_texture_channel", PoolRealArray([0.0, 1.0, 0.0, 0.0]))
		m.set_shader_param("emission_energy", parameters.emission_energy)
		m.set_shader_param("texture_emission", get_generated_texture("emission", file_prefix))
		m.set_shader_param("normal_scale", parameters.normal_scale)
		m.set_shader_param("texture_normal", get_generated_texture("normal", file_prefix))
		m.set_shader_param("depth_scale", parameters.depth_scale * 0.2)
		m.set_shader_param("texture_depth", get_generated_texture("depth", file_prefix))

# Export

func get_export_profiles() -> Array:
	return shader_model.exports.keys()

func get_export_extension(profile : String) -> String:
	return shader_model.exports[profile].export_extension

func export_material(prefix, profile) -> void:
	for f in shader_model.exports[profile].files:
		match f.type:
			"texture":
				var file_name = f.file_name.replace("$(file_prefix)", prefix)
				if f.has("conditions"):
					var condition = f.conditions
					for input_index in range(shader_model.inputs.size()):
						var input = shader_model.inputs[input_index]
						var is_input_connected = "true" if get_source(input_index) != null else "false"
						condition = condition.replace("$(connected:"+input.name+")", is_input_connected)
					var expr = Expression.new()
					var error = expr.parse(condition, [])
					if error != OK:
						print("Error in expression: "+expr.get_error_text())
						continue
					if !expr.execute():
						continue
				var result = render(f.output, get_image_size())
				while result is GDScriptFunctionState:
					result = yield(result, "completed")
				result.save_to_file(file_name)
				result.release()

func _serialize(data: Dictionary) -> Dictionary:
	return data
