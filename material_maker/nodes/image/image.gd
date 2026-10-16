class_name MMGraphImage
extends MMGraphNodeGeneric

func on_parameter_changed(p : String, v) -> void:
	super.on_parameter_changed(p, v)
	if p == "filter":
		var image_edit : ImagePickerButton = controls["image"]
		image_edit.set_filter(v)
