tool
extends EditorScript

# This script grabs all textures from a theme and throws them into the icons

func _run():
	for t in ["res://material_maker/theme/default.tres"]:
		optimize_theme(t)

func optimize_theme(theme_path):
	# change this to share icons between themes
	var icon_dir = theme_path.get_basename()
	Directory.new().make_dir(icon_dir)
	var theme : Theme = load(theme_path)
	var new_theme : Theme = Theme.new()
	for stylebox_name in theme.get_stylebox_types():
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
	ResourceSaver.save(theme_path, new_theme)
	print("done")
