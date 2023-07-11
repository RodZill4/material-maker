@tool
extends EditorScript

# This script grabs all textures from a theme and throws them into the icons

func _run():
	create_theme_variation("res://material_maker/theme/dark.tres", "res://material_maker/theme/light.tres", invert_color, true)
	fix_theme_geometry("res://material_maker/theme/dark.tres", "res://material_maker/theme/default.tres")
	create_theme_variation("res://material_maker/theme/default.tres", "res://material_maker/theme/green.tres", colorize.bind(0.3))
	create_theme_variation("res://material_maker/theme/default.tres", "res://material_maker/theme/birch.tres", colorize.bind(0.1))
	create_theme_variation("res://material_maker/theme/default.tres", "res://material_maker/theme/mangosteen.tres", colorize.bind(0.9))
	
func invert_color(c : Color) -> Color:
	return c.inverted()

func colorize(c : Color, hue : float) -> Color:
	c.h = hue
	return c

func create_theme_variation(src : String, dst : String, color_fct : Callable, invert_icons : bool = false):
	var src_theme : Theme = load(src)
	var dst_theme : Theme = Theme.new()
	var references : Dictionary = {}
	for type_name in src_theme.get_type_list():
		#print(type_name)
		for t in range(Theme.DATA_TYPE_MAX):
			for theme_item_name in src_theme.get_theme_item_list(t, type_name):
				#print("  - "+theme_item_name)
				var src_item = src_theme.get_theme_item(t, theme_item_name, type_name)
				var dst_item = src_item
				if references.has(src_item):
					dst_item = references[src_item]
				else:
					match t:
						Theme.DATA_TYPE_COLOR:
							dst_item = color_fct.call(src_item)
						Theme.DATA_TYPE_ICON:
							if invert_icons:
								dst_item = load(src_item.resource_path.replace("/dark/", "/light/"))
						Theme.DATA_TYPE_STYLEBOX:
							dst_item = src_item.duplicate(true)
							for p in dst_item.get_property_list():
								if p.usage == 6 and dst_item.get(p.name) is Color:
									dst_item.set(p.name, color_fct.call(dst_item.get(p.name)))
					references[src_item] = dst_item
				dst_theme.set_theme_item(t, theme_item_name, type_name, dst_item)
	print("Saving "+dst)
	ResourceSaver.save(dst_theme, dst)

func fix_theme_geometry(src : String, dst : String):
	var src_theme : Theme = load(src)
	var dst_theme : Theme = load(dst)
	var references : Dictionary = {}
	for type_name in src_theme.get_type_list():
		#print(type_name)
		for t in range(Theme.DATA_TYPE_MAX):
			for theme_item_name in src_theme.get_theme_item_list(t, type_name):
				#print("  - "+theme_item_name)
				var src_item = src_theme.get_theme_item(t, theme_item_name, type_name)
				var dst_item = dst_theme.get_theme_item(t, theme_item_name, type_name)
				if references.has(src_item):
					dst_item = references[src_item]
				else:
					match t:
						Theme.DATA_TYPE_COLOR, Theme.DATA_TYPE_ICON:
							continue
						Theme.DATA_TYPE_STYLEBOX:
							var new_dst_item = src_item.duplicate(true)
							for p in dst_item.get_property_list():
								if p.usage == 6 and dst_item.get(p.name) is Color:
									new_dst_item.set(p.name, dst_item.get(p.name))
							dst_item = new_dst_item
					references[src_item] = dst_item
				dst_theme.set_theme_item(t, theme_item_name, type_name, dst_item)
	print("Saving "+dst)
	ResourceSaver.save(dst_theme, dst)

func optimize_theme(theme_path):
	# change this to share icons between themes
	var icon_dir = theme_path.get_basename()
	var theme : Theme = load(theme_path)
	var new_theme : Theme = Theme.new()
	for stylebox_name in theme.get_stylebox_type_list():
		for color_name in theme.get_color_list(stylebox_name):
			new_theme.set_color(color_name, stylebox_name, theme.get_color(color_name, stylebox_name))
		for constant_name in theme.get_constant_list(stylebox_name):
			new_theme.set_constant(constant_name, stylebox_name, theme.get_constant(constant_name, stylebox_name))
		for font_name in theme.get_font_list(stylebox_name):
			new_theme.set_font(font_name, stylebox_name, theme.get_font(font_name, stylebox_name).duplicate())
		for sb_name in theme.get_stylebox_list(stylebox_name):
			var stylebox = theme.get_stylebox(sb_name, stylebox_name)
			if stylebox is StyleBoxTexture:
				var sb = theme.get_stylebox(sb_name, stylebox_name)
				var new_sb = sb.duplicate(true)
				for t in [ "texture", "normal_map" ]:
					if new_sb[t] != null:
						var png_name = ("sb_"+stylebox_name+"_"+sb_name+"_"+t).to_lower()
						var png_path : String = icon_dir+"/"+png_name+".png"
						var new_icon = load(png_path)
						if new_icon == null:
							print("missing icon "+png_path)
							var image = new_sb[t].get_data()
							if image != null:
								print("saving icon "+png_path)
								image.save_png(png_path)
								new_icon = load(png_path)
								if new_icon != null:
									new_sb[t] = new_icon
						else:
							new_sb[t] = new_icon
			else:
				new_theme.set_stylebox(sb_name, stylebox_name, theme.get_stylebox(sb_name, stylebox_name))
		for icon_name in theme.get_icon_list(stylebox_name):
			var png_name = (stylebox_name+"_"+icon_name).to_lower()
			var png_path : String = icon_dir+"/"+png_name+".png"
			var new_icon = load(png_path)
			if new_icon == null:
				print("missing icon "+png_path)
				var icon = theme.get_icon(icon_name, stylebox_name)
				var image = icon.get_data()
				if image != null:
					print("saving icon "+png_path)
					image.save_png(png_path)
					new_icon = load(png_path)
					if new_icon != null:
						new_theme.set_icon(icon_name, stylebox_name, new_icon)
			else:
				new_theme.set_icon(icon_name, stylebox_name, new_icon)
	ResourceSaver.save(new_theme, theme_path)
	print("done")
