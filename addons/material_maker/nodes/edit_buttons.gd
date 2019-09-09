extends HBoxContainer

func connect_buttons(object, edit_fct, load_fct, save_fct):
	$Edit.connect("pressed", object, edit_fct)
	$Load.connect("pressed", object, load_fct)
	$Save.connect("pressed", object, save_fct)