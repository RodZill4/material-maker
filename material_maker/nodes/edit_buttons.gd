extends HBoxContainer

func connect_buttons(object, edit_fct, load_fct, save_fct) -> void:
	$Edit.connect("pressed",Callable(object,edit_fct))
	$Load.connect("pressed",Callable(object,load_fct))
	$Save.connect("pressed",Callable(object,save_fct))
