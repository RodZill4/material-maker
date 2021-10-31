extends WindowDialog

var project

func _ready():
	pass

func _on_Margin_minimum_size_changed():
	set_size($Margin.get_minimum_size())

func edit_settings(p):
	project = p
	var settings : Dictionary = project.get_settings()
	$Margin/VBox/TextureSize/SizeOptionButton.size_value = settings.texture_size
	$Margin/VBox/PaintEmission.pressed = settings.paint_emission
	$Margin/VBox/PaintNormal.pressed = settings.paint_normal
	$Margin/VBox/PaintDepth.pressed = settings.paint_depth
	$Margin/VBox/Bump/PaintBump.pressed = settings.paint_depth_as_bump
	$Margin/VBox/Bump/BumpStrength.value = settings.bump_strength
	popup_centered()

func apply_settings():
	var settings : Dictionary = {}
	settings.texture_size = $Margin/VBox/TextureSize/SizeOptionButton.size_value
	settings.paint_emission = $Margin/VBox/PaintEmission.pressed
	settings.paint_normal = $Margin/VBox/PaintNormal.pressed
	settings.paint_depth = $Margin/VBox/PaintDepth.pressed
	settings.paint_depth_as_bump = $Margin/VBox/Bump/PaintBump.pressed
	settings.bump_strength = $Margin/VBox/Bump/BumpStrength.value
	project.set_settings(settings)

func ok():
	apply_settings()
	queue_free()
