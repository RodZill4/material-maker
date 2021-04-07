extends Area

var prev_pos = null
var last_click_pos = null
var last_pos2d = null;

onready var viewport = $Viewport

func ui_raycast_hit_event(position, click, release):
	# note: this transform assumes that the unscaled area is [-0.5, -0.5] to [0.5, 0.5] in size
	var local_position = to_local(position);
	var pos2d = Vector2(local_position.x, -local_position.y)
	pos2d = pos2d + Vector2(0.5, 0.5)
	pos2d.x *= viewport.size.x
	pos2d.y *= viewport.size.y

	if (click || release):
		var e = InputEventMouseButton.new();
		e.pressed = click;
		e.button_index = BUTTON_LEFT;
		e.position = pos2d;
		e.global_position = pos2d;
		viewport.input(e);

	elif (last_pos2d != null && last_pos2d != pos2d):
		var e = InputEventMouseMotion.new();
		e.relative = pos2d - last_pos2d;
		e.speed = (pos2d - last_pos2d) / 16.0; #?? chose an arbitrary scale here for now
		e.global_position = pos2d;
		e.position = pos2d;
		viewport.input(e);
	last_pos2d = pos2d;

