extends TabContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _drop_data(at_position, data):
	var source : TabContainer = get_node(data.from_path)
	var panel = source.get_tab_control(data.tabc_element)
	source.remove_child(panel)
	add_child(panel)

func _can_drop_data(at_position, data):
	if data is Dictionary and data.has("type") and data.type == "tabc_element":
		return true
	return false
