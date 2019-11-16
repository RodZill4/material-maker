tool
extends MMGenBase
class_name MMGenMaterial

var material : SpatialMaterial
var generated_textures = {}

const TEXTURE_LIST = [
	{ port=0, texture="albedo" },
	{ port=3, texture="emission" },
	{ port=4, texture="normal" },
	{ ports=[5, 2, 1], default_values=["1.0", "1.0", "1.0"], texture="orm" },
	{ port=6, texture="depth" },
	{ port=7, texture="subsurf_scatter" }
]

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

func get_parameter_defs() -> Array:
	return [
		{ name="albedo_color", label="Albedo", type="color", default={ r=1.0, g=1.0, b=1.0, a=1.0} },
		{ name="metallic", label="Metallic", type="float", min=0.0, max=1.0, step=0.05, default=1.0 },
		{ name="roughness", label="Roughness", type="float", min=0.0, max=1.0, step=0.05, default=1.0 },
		{ name="emission_energy", label="Emission", type="float", min=0.0, max=8.0, step=0.05, default=1.0 },
		{ name="normal_scale", label="Normal", type="float", min=0.0, max=8.0, step=0.05, default=1.0 },
		{ name="ao_light_affect", label="Ambient occlusion", type="float", min=0.0, max=1.0, step=0.05, default=1.0 },
		{ name="depth_scale", label="Depth", type="float", min=0.0, max=1.0, step=0.05, default=1.0 },
		{ name="subsurf_scatter_strength", label="Subsurf. Scatter.", type="float", min=0.0, max=1.0, step=0.05, default=0.0 },
		{ name="size", label="Size", type="size", first=TEXTURE_SIZE_MIN, last=TEXTURE_SIZE_MAX, default=TEXTURE_SIZE_DEFAULT }
	]

func get_input_defs() -> Array:
	return [
		{ name="albedo_texture", label="", type="rgb" },
		{ name="metallic_texture", label="", type="f" },
		{ name="roughness_texture", label="", type="f" },
		{ name="emission_texture", label="", type="rgb" },
		{ name="normal_texture", label="", type="rgb" },
		{ name="ao_texture", label="", type="f" },
		{ name="depth_texture", label="", type="f" },
		{ name="subsurf_scatter_texture", label="", type="f" }
	]

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
			var source = get_source(t.port)
			if source == null:
				generated_textures[t.texture] = null
				continue
			result = source.generator.render(source.output_index, get_image_size())
		elif t.has("ports"):
			var context : MMGenContext = MMGenContext.new()
			var code = []
			var shader_textures = {}
			var sources = 0
			for i in range(t.ports.size()):
				var source = get_source(t.ports[i])
				if source != null:
					var status = source.generator.get_shader_code("UV", source.output_index, context)
					while status is GDScriptFunctionState:
						status = yield(status, "completed")
					code.push_back(status)
					for t in status.textures.keys():
						shader_textures[t] = status.textures[t]
					sources += 1
				else:
					code.push_back({ defs="", code="", f=t.default_values[i] })
			if sources == 0:
				generated_textures[t.texture] = null
				continue
			var shader : String = mm_renderer.generate_combined_shader(code[0], code[1], code[2])
			result = mm_renderer.render_shader(shader, shader_textures, get_image_size())
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
		update_spatial_material(m)

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

func update_spatial_material(m, file_prefix = null) -> void:
	var texture

	if m is SpatialMaterial:
		# Make the material double-sided for better visiblity in the preview
		m.params_cull_mode = SpatialMaterial.CULL_DISABLED
		# Albedo
		m.albedo_color = parameters.albedo_color
		m.albedo_texture = get_generated_texture("albedo", file_prefix)
		m.metallic = parameters.metallic
		m.roughness = parameters.roughness
		# Metallic
		texture = get_generated_texture("orm", file_prefix)
		m.metallic_texture = texture
		m.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_BLUE
		# Roughness
		m.roughness_texture = texture
		m.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN
		# Emission
		texture = get_generated_texture("emission", file_prefix)
		if texture != null:
			m.emission_enabled = true
			m.emission_energy = parameters.emission_energy
			m.emission_texture = texture
		else:
			m.emission_enabled = false
		# Normal map
		texture = get_generated_texture("normal", file_prefix)
		if texture != null:
			m.normal_enabled = true
			m.normal_texture = texture
		else:
			m.normal_enabled = false
		# Ambient occlusion
		if get_source(5) != null:
			m.ao_enabled = true
			m.ao_light_affect = parameters.ao_light_affect
			m.ao_texture = m.metallic_texture
			m.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
		else:
			m.ao_enabled = false
		# Depth
		texture = get_generated_texture("depth", file_prefix)
		if texture != null:
			m.depth_enabled = true
			m.depth_deep_parallax = true
			m.depth_scale = parameters.depth_scale * 0.2
			m.depth_texture = texture
		else:
			m.depth_enabled = false
		# Subsurface scattering
		texture = get_generated_texture("subsurf_scatter", file_prefix)
		if texture != null:
			m.subsurf_scatter_enabled = true
			m.subsurf_scatter_strength = parameters.subsurf_scatter_strength
			m.subsurf_scatter_texture = texture
		else:
			m.subsurf_scatter_enabled = false
	else:
		m.set_shader_param("albedo", parameters.albedo_color)
		m.set_shader_param("texture_albedo", get_generated_texture("albedo", file_prefix))
		m.set_shader_param("metallic", parameters.metallic)
		m.set_shader_param("roughness", parameters.roughness)
		m.set_shader_param("texture_metallic", get_generated_texture("orm", file_prefix))
		m.set_shader_param("metallic_texture_channel", PoolRealArray([0.0, 0.0, 1.0, 0.0]))
		m.set_shader_param("texture_roughness", get_generated_texture("orm", file_prefix))
		m.set_shader_param("roughness_texture_channel", PoolRealArray([0.0, 1.0, 0.0, 0.0]))
		m.set_shader_param("emission_energy", parameters.emission_energy)
		m.set_shader_param("texture_emission", get_generated_texture("emission", file_prefix))
		m.set_shader_param("normal_scale", parameters.normal_scale)
		m.set_shader_param("texture_normal", get_generated_texture("normal", file_prefix))
		m.set_shader_param("depth_scale", parameters.depth_scale * 0.2)
		m.set_shader_param("texture_depth", get_generated_texture("depth", file_prefix))

func export_textures(prefix, editor_interface = null) -> SpatialMaterial:
	for t in TEXTURE_LIST:
		var texture = generated_textures[t.texture]
		if texture != null:
			var image = texture.get_data()
			image.save_png("%s_%s.png" % [ prefix, t.texture ])
	if Engine.editor_hint and editor_interface != null:
		var resource_filesystem = editor_interface.get_resource_filesystem()
		resource_filesystem.scan()
		yield(resource_filesystem, "resources_reimported")
		print("resources_reimported")
		var new_material = SpatialMaterial.new()
		update_spatial_material(new_material, prefix)
		var file_name : String = "%s.tres" % [ prefix ]
		ResourceSaver.save(file_name, new_material)
		resource_filesystem.update_file(file_name)
		return new_material

	return null

func _serialize(data: Dictionary) -> Dictionary:
	return data
