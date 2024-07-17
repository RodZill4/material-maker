extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	mm_logger.set_logger(self)

func url_data_from_string(s : String) -> Dictionary:
	var fields = s.split(",")
	var data : Dictionary = {}
	for f in fields:
		var sep = f.split(":", 1)
		if sep.size() == 2:
			data[sep[0]] = sep[1]
	return data

func string_to_bbcode(s : String) -> String:
	var changed : bool = true
	while changed:
		changed = false
		var l : int = s.find("[[")
		if l != -1:
			var l2 : int = s.find("]]", l)
			if l2 != -1:
				changed = true
				var url : String = s.substr(l+2, l2-l-2)
				var url_string : String = url
				var data : Dictionary = url_data_from_string(url)
				if data.has("type"):
					match data.type:
						"nodesection":
							url_string = data.section+" section of node "+data.node
				s = s.left(l)+"[url="+url+"]"+url_string+"[/url]"+s.right(-l2-2)
	return s

func write(l: String, m : String):
	if l == "":
		$RichTextLabel.text += string_to_bbcode(m)+"\n"
	elif l == "ERROR":
		$RichTextLabel.text += "[color=red]"+l+": "+m+"[/color]\n"
	else:
		$RichTextLabel.text += l+": "+m+"\n"

var generator = null

func _on_rich_text_label_meta_clicked(meta):
	var data : Dictionary = url_data_from_string(meta)
	match data.type:
		"nodesection":
			generator = instance_from_id(data.nodeid.right(-1).to_int())
			generator.edit(self, data.section)

func update_shader_generator(shader_model) -> void:
	generator.set_shader_model(shader_model)

func toggle():
	visible = not visible
