extends PanelContainer


func _on_ready() -> void:
	%GridDensity.value = %PolygonEditor.axes_density - 1.0


func _on_grid_density_value_changed(value: Variant) -> void:
	%PolygonEditor.axes_density = value + 1.0
	%PolygonEditor.queue_redraw()
