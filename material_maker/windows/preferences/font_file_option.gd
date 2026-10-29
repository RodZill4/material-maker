class_name FontFileOption
extends FileOption

func _ready() -> void:
	super._ready()
	$FilePickerButton.file_selected.connect(file_selected)

func init_from_config(config : ConfigFile) -> void:
	super.init_from_config(config)
	file_selected.call_deferred($FilePickerButton.path)

func file_selected(file_path : String) -> void:
	if FileAccess.file_exists(file_path):
		var f : FontFile = FontFile.new()
		var err : Error = f.load_dynamic_font(file_path)
		if err == OK:
			$FilePickerButton.text = f.get_font_name()
