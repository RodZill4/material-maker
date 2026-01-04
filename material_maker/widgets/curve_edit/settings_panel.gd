extends PanelContainer


func _on_ready() -> void:
	%GridDensity.value = %CurveEditor.axes_density - 1.0


func _on_grid_density_value_changed(value: Variant) -> void:
	%CurveEditor.axes_density = value + 1.0
	%CurveEditor.queue_redraw()
