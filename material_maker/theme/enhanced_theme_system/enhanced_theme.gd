@tool
extends Theme
class_name EnhancedTheme


@export var base_theme: Theme:
	set(val):
		if base_theme != val:
			if base_theme:
				base_theme.changed.disconnect(update)
			if val:
				val.changed.connect(update)
		base_theme = val
		#queue_update()
	
@export var scale: float = 1.0:
	set(val):
		scale = val
		#queue_update()


@export_custom(PROPERTY_HINT_ARRAY_TYPE, "ColorSwap") var icon_color_swaps := []:
	set(val):
		icon_color_swaps = val
		#queue_update()


var owned_properties := ["base_theme", "scale", "icon_color_swaps", "resource_path", "name", "owned_properties"]
var updating := false

var update_queued := false
#
#func _init() -> void:
	#clear()
	#update()

#
#func queue_update():
	#if update_queued:
		#return
	#update_queued = true
	#await Engine.get_main_loop().create_timer(0.5).timeout
	#update()
	#update_queued = false


func update(at:Node=null) -> void:
	if updating:
		return
	
	if not base_theme:
		clear()
		return
	
	if at:
		at.theme = null
	
	updating = true
	print("THEME UPDATE")
	
	clear()

	for i in base_theme.get_property_list():
		if not i.name.begins_with("resource_") and i.usage & PROPERTY_USAGE_EDITOR and i.name != "script":
			var val: Variant = base_theme.get(i.name)
			if val is Resource:
				if val is AtlasTexture and get(i.name) is AtlasTexture:
					val = get(i.name)
				else:
					val = val.duplicate()
			set(i.name, val)
	
	## FONT SIZE
	for type in get_font_size_type_list():
		for font_size_name in get_font_size_list(type):
			set_font_size(font_size_name, type, base_theme.get_font_size(font_size_name, type) * scale)
	
	default_font_size = base_theme.default_font_size * scale
	
	## STYLEBOXES
	for type in get_stylebox_type_list():
		for stylebox_name in get_stylebox_list(type):
			var base := base_theme.get_stylebox(stylebox_name, type)
			var this := get_stylebox(stylebox_name, type)
			this.content_margin_left = base.content_margin_left * scale
			this.content_margin_top = base.content_margin_top * scale
			this.content_margin_right = base.content_margin_right * scale
			this.content_margin_bottom = base.content_margin_bottom * scale
			
			if "expand_margin_top" in base:
				this.expand_margin_left = base.expand_margin_left * scale
				this.expand_margin_top = base.expand_margin_top * scale
				this.expand_margin_right = base.expand_margin_right * scale
				this.expand_margin_bottom = base.expand_margin_bottom * scale
			
			if "corner_radius_top_left" in base:
				this.corner_radius_top_left = base.corner_radius_top_left * scale
				this.corner_radius_top_right = base.corner_radius_top_right * scale
				this.corner_radius_bottom_right = base.corner_radius_bottom_right * scale
				this.corner_radius_bottom_left = base.corner_radius_bottom_left * scale
	
			if "border_width_top" in base:
				this.border_width_left = base.border_width_left * scale
				this.border_width_top = base.border_width_top * scale
				this.border_width_right = base.border_width_right * scale
				this.border_width_bottom = base.border_width_bottom * scale
	
	## SEPARATIONS
	for type in get_constant_type_list():
		for constant_name in get_constant_list(type):
			set_constant(constant_name, type, base_theme.get_constant(constant_name, type) * scale)
	
	## ICONS
	for type in get_icon_type_list():
		for icon_name in get_icon_list(type):
			var base_texture := base_theme.get_icon(icon_name, type)
			
			var path := ""
			if base_texture is not AtlasTexture or base_texture.atlas == null:
				continue
			elif base_texture.atlas.resource_path.ends_with("svg"):
				path = base_texture.atlas.resource_path
			else:
				continue
			
			var texture: AtlasTexture = get_icon(icon_name, type)
			
			texture.atlas = get_dynamic_svg(path,  scale, icon_color_swaps)

			var base_region: Rect2 = base_texture.region
			texture.region.position = base_region.position * scale
			
			texture.region.size  = base_region.size * scale
			set_icon(icon_name, type, texture)
	
	emit_changed()
	
	updating = false
	
	if at:
		at.theme = self


func get_dynamic_svg(image_path:String, image_scale:float, color_swaps : Array= []) -> ImageTexture:
	var file := FileAccess.open(image_path, FileAccess.READ)
	var file_text := file.get_as_text()
	file.close()
	
	##print(color_swaps)
	var regex := RegEx.create_from_string(r"e-[86754]")
	file_text = regex.sub(file_text, "", true)
	
	for swap in color_swaps:
		if swap == null:
			break
		#print("replace ", swap.orig.to_html(), " with ", swap.target.to_html())
		file_text = file_text.replace(swap.orig.to_html(false), swap.target.to_html(false))
	
	var img := Image.new()
	img.load_svg_from_buffer(file_text.to_utf8_buffer(), image_scale)

	return ImageTexture.create_from_image(img)


func _validate_property(property: Dictionary) -> void:
	if property.name.begins_with("default_") or "/" in property.name:
		property.usage = PROPERTY_USAGE_INTERNAL
		#print(property.name)
