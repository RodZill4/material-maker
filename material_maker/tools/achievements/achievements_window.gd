extends Window

func _ready():
	var csf : float = mm_globals.main_window.get_window().content_scale_factor
	content_scale_factor = csf
	min_size = size * content_scale_factor


func set_achievements(achievements, unlocked):
	var container = $VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer
	var total : int = 0
	var total_unlocked : int = 0
	for s in achievements:
		var label = load("res://material_maker/tools/achievements/achievement_section.tscn").instantiate()
		label.text = s.name
		container.add_child(label)
		var section : VBoxContainer = VBoxContainer.new()
		container.add_child(section)
		var locked_count : int = 0
		for a in s.achievements:
			var achievement = load("res://material_maker/tools/achievements/achievement.tscn").instantiate()
			achievement.custom_minimum_size.y = 100
			section.add_child(achievement)
			if unlocked.find(a.id) != -1:
				achievement.set_texts(a.name, a.description, true)
				total_unlocked += 1
			else:
				achievement.set_texts("? ? ? ? ? ?", a.hint)
				section.move_child(achievement, locked_count)
				locked_count += 1
			total += 1
	$VBoxContainer/Label.text = "Total achievements completed: %d/%d" % [ total_unlocked, total ]


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


func _on_close_requested() -> void:
	queue_free()
