extends WindowDialog

var config : ConfigFile

signal config_modified()

func _ready():
	pass # Replace with function body.

func edit_preferences(c : ConfigFile) -> void:
	config = c
	update_controls(self)
	popup_centered()

func update_controls(p : Node) -> void:
	for c in p.get_children():
		if c.has_method("init_from_config"):
			c.init_from_config(config)
		update_controls(c)

func update_config(p : Node) -> void:
	for c in p.get_children():
		if c.has_method("update_config"):
			c.update_config(config)
		update_config(c)

func _on_Apply_pressed():
	update_config(self)

func _on_OK_pressed():
	update_config(self)
	queue_free()

func _on_Cancel_pressed():
	queue_free()
