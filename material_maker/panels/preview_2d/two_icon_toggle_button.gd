extends Button

@export var icon_normal : Texture2D 
@export var icon_pressed : Texture2D 

func _ready() -> void:
	toggled.connect(_on_toggled)
	_on_toggled(button_pressed)


func _on_toggled(toggled:= false):
	if button_pressed:
		icon = icon_pressed
	else:
		icon = icon_normal
		
