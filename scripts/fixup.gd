#!/usr/bin/env -S godot --no-window -s

extends SceneTree

func _init():
	var show_help = true
	for mmg_filename in OS.get_cmdline_args():
		if mmg_filename.ends_with('.mmg'):
			print(mmg_filename)
			var gen = load("res://addons/material_maker/engine/loader.gd").new().load_gen(mmg_filename)
			var graph_node_generic = load("res://material_maker/nodes/generic/generic.gd")
			graph_node_generic.do_save_generator(mmg_filename, gen)

			show_help = false

	if show_help:
		print("To use, run this command from the project directory:")
		print()
		print("	MM_WRITE_NEW_FORMAT=1 ./scripts/fixup.gd addons/material_maker/nodes/*.mmg")
		print()

	quit()

