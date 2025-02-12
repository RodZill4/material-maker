extends PanelContainer


func add_effects_button(text:String, callable: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callable)
	$VBox.add_child(button)
	return button
