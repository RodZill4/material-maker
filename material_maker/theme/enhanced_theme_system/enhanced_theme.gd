@tool
extends Theme
class_name EnhancedTheme

## This is a resource that creates a new theme based on a base-theme.
## For now only color-swapping is used.
## In the future scaling could be done using this system as well.


@export var base_theme: Theme

#@export var scale: float = 1.0:
	#set(val):
		#scale = val


@export var font_color_swaps: Array[ColorSwap] = []
@export var icon_color_swaps: Array[ColorSwap] = []
@export var theme_color_swaps: Array[ColorSwap] = []

var updating := false


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
		if i.usage & PROPERTY_USAGE_EDITOR and not i.name.begins_with("resource_") and i.name != "script":
			var val: Variant = base_theme.get(i.name)
			if val is Resource:
				if val is AtlasTexture and get(i.name) is AtlasTexture:
					val = get(i.name)
				elif val is Font:
					pass
				else:
					val = val.duplicate()
			set(i.name, val)

	### FONT SIZE
	#for type in get_font_size_type_list():
		#for font_size_name in get_font_size_list(type):
			#set_font_size(font_size_name, type, base_theme.get_font_size(font_size_name, type) * scale)
#
	#default_font_size = base_theme.default_font_size * scale

	var font_color_swap_dict := {}
	for swap in font_color_swaps:
		font_color_swap_dict[swap.orig.to_html()] = swap.target.to_html()

	var theme_color_swap_dict := {}
	for swap in theme_color_swaps:
		theme_color_swap_dict[swap.orig.to_html()] = swap.target.to_html()

	var icon_color_swap_dict := {}
	for swap in icon_color_swaps:
		icon_color_swap_dict[swap.orig.to_html()] = swap.target.to_html()

	## COLORS
	for type in get_color_type_list():
		for color_name in get_color_list(type):
			if "font_" in color_name:
				if get_color(color_name, type).to_html() in font_color_swap_dict:
					set_color(color_name, type, Color(font_color_swap_dict[get_color(color_name, type).to_html()]))
			elif "icon_" in color_name:
				if get_color(color_name, type).to_html() in icon_color_swap_dict:
					set_color(color_name, type, Color(icon_color_swap_dict[get_color(color_name, type).to_html()]))
			else:
				if get_color(color_name, type).to_html() in theme_color_swap_dict:
					set_color(color_name, type, Color(theme_color_swap_dict[get_color(color_name, type).to_html()]))


	## STYLEBOXES
	for type in get_stylebox_type_list():
		for stylebox_name in get_stylebox_list(type):
			# ADJUST SIZE
			var base := base_theme.get_stylebox(stylebox_name, type)
			var this := get_stylebox(stylebox_name, type)
			#this.content_margin_left = base.content_margin_left * scale
			#this.content_margin_top = base.content_margin_top * scale
			#this.content_margin_right = base.content_margin_right * scale
			#this.content_margin_bottom = base.content_margin_bottom * scale
#
			#if "expand_margin_top" in base:
				#this.expand_margin_left = base.expand_margin_left * scale
				#this.expand_margin_top = base.expand_margin_top * scale
				#this.expand_margin_right = base.expand_margin_right * scale
				#this.expand_margin_bottom = base.expand_margin_bottom * scale
#
			#if "corner_radius_top_left" in base:
				#this.corner_radius_top_left = base.corner_radius_top_left * scale
				#this.corner_radius_top_right = base.corner_radius_top_right * scale
				#this.corner_radius_bottom_right = base.corner_radius_bottom_right * scale
				#this.corner_radius_bottom_left = base.corner_radius_bottom_left * scale
#
			#if "border_width_top" in base:
				#this.border_width_left = base.border_width_left * scale
				#this.border_width_top = base.border_width_top * scale
				#this.border_width_right = base.border_width_right * scale
				#this.border_width_bottom = base.border_width_bottom * scale

			# Adjust Colors
			if "bg_color" in this:
				if this.bg_color.to_html() in theme_color_swap_dict:
					this.bg_color = Color(theme_color_swap_dict[this.bg_color.to_html()])

			if "border_color" in this:
				if this.border_color.to_html() in theme_color_swap_dict:
					this.border_color = Color(theme_color_swap_dict[this.border_color.to_html()])


	### SEPARATIONS
	#for type in get_constant_type_list():
		#for constant_name in get_constant_list(type):
			#set_constant(constant_name, type, base_theme.get_constant(constant_name, type) * scale)

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
			var texture_scale: float = texture.get_meta("scale", 1)# * scale

			if base_texture.has_meta("recolor"):
				texture.atlas = get_dynamic_svg(path, texture_scale, icon_color_swaps)
			else:
				texture.atlas = get_dynamic_svg(path, texture_scale)

			var base_region: Rect2 = base_texture.region
			texture.region.position = base_region.position * texture_scale

			texture.region.size  = base_region.size * texture_scale
			set_icon(icon_name, type, texture)

	emit_changed()

	updating = false

	if at:
		at.theme = self


func get_dynamic_svg(image_path:String, image_scale:float, color_swaps : Array= []) -> ImageTexture:
	if FileAccess.file_exists(image_path.trim_suffix(".svg")+"_export.svg"):
		image_path = image_path.trim_suffix(".svg")+"_export.svg"
	var file := FileAccess.open(image_path, FileAccess.READ)
	var file_text := file.get_as_text()
	file.close()

	#var regex := RegEx.create_from_string(r"(?<=\d)e-\d")
	#file_text = regex.sub(file_text, "", true)

	for swap in color_swaps:
		if swap == null:
			break
		file_text = file_text.replace(swap.orig.to_html(false), swap.target.to_html(false))

	var img := Image.new()
	img.load_svg_from_buffer(file_text.to_utf8_buffer(), image_scale)

	return ImageTexture.create_from_image(img)

#
#func _validate_property(property: Dictionary) -> void:
	#if property.name.begins_with("default_") or "/" in property.name:
		#property.usage = PROPERTY_USAGE_INTERNAL
