extends Control

func _on_projects_panel_resized():
	var preview_position : Vector2 = Vector2(0.0, 0.0)
	var preview_size : Vector2 = size
	preview_position.y += $Projects/TabBar.size.y
	preview_size.y -= $Projects/TabBar.size.y
	$BackgroundPreviews.position = preview_position
	$BackgroundPreviews.size = preview_size
