extends Node

var unlocked : Array = []

const ACHIEVEMENTS : Array = [
	{
		name = "User Interface",
		achievements = [
			{
				id = "ui_start",
				name = "First step",
				hint = "Start Material Maker for the first time",
				description = "Welcome!"
			},
			{
				id = "ui_2d_preview_to_reference",
				name = "",
				hint = "Add a rendered preview to the reference panel",
				description = ""
			},
			{
				id = "ui_2d_preview_change_grid",
				name = "",
				hint = "Change the grid in the 2D preview",
				description = ""
			},
			{
				id = "ui_3d_preview_custom_mesh",
				name = "",
				hint = "Use a custom mesh in the 3D preview",
				description = ""
			},
			{
				id = "ui_3d_preview_bake_texture",
				name = "",
				hint = "Bake a texture from the 3D preview",
				description = ""
			},
			{
				id = "ui_3d_preview_change_environment",
				name = "",
				hint = "Select a new environment in the 3D preview",
				description = ""
			},
			{
				id = "ui_add_reference",
				name = "",
				hint = "Add an image to the reference panel",
				description = ""
			},
			{
				id = "ui_reference_sample gradient",
				name = "",
				hint = "Sample a gradient from the reference panel",
				description = ""
			},
			{
				id = "ui_doc",
				name = "The Fine Manual",
				hint = "Read the user manual",
				description = "You read it all, haven't you?"
			},
		]
	},
	{
		name = "Material authoring",
		achievements = [
			{
				id = "ui_dropnode",
				name = "Add your first node",
				hint = "Drop a node from the Library to a graph",
				description = "You did it!"
			},
			{
				id = "ui_createnode",
				name = "Add your second node",
				hint = "Create a node using the add node menu",
				description = "You did it again!"
			},
			{
				id = "ui_group",
				name = "Divide and Conquer",
				hint = "Create a node group that contains at least 5 nodes",
				description = "Keep your graphs organized"
			},
			{
				id = "ui_warehousemanager",
				name = "Warehouse Manager",
				hint = "Store a few nodes in a user library",
				description = "Why do it again if you did it already?"
			},
			{
				id = "ui_loop",
				name = "Chicken and egg",
				hint = "Try to create a loop in your graph",
				description = "You tried to create a loop in the graph, and failed. You failed, didn't you? Well if you succeeded, it's a bug. Please report it."
			},
			{
				id = "ui_math_circle",
				name = "The inner circle",
				hint = "Create a circle profile using the Math node",
				description = "Pythagoras is proud of you (I guess)."
			}
		]
	}
]

var config = null

func set_config(config_cache):
	config = config_cache
	if config.has_section_key("achievements", "unlocked"):
		unlocked = config.get_value("achievements", "unlocked").split(",")
	unlock("ui_start")

func unlock(achievement : String):
	if unlocked.find(achievement) != -1:
		return
	unlocked.push_back(achievement)
	config.set_value("achievements", "unlocked", PoolStringArray(unlocked).join(","))
	for s in ACHIEVEMENTS:
		for a in s.achievements:
			if achievement == a.id:
				var achievement_widget = load("res://material_maker/tools/achievements/new_achievement.tscn").instance()
				achievement_widget.set_texts(a.name, a.description)
				add_child(achievement_widget)
				return
