extends Control

var last_value : int = 0
var start_time : int = 0
var max_render_queue_size : int = 0

var auto : bool = true
var fast_counter : int = 0

const ITEM_AUTO : int           = 1000
const ITEM_RENDER_ENABLED : int = 1001

func _ready() -> void:
	$PopupMenu.add_check_item("Auto", ITEM_AUTO)
	$PopupMenu.set_item_checked($PopupMenu.get_item_index(ITEM_AUTO), true)
	for i in range(8):
		$PopupMenu.add_radio_check_item("%d renderer%s" % [ i+1, "s" if i > 0 else "" ], i+1)
	$PopupMenu.set_item_checked($PopupMenu.get_item_index(mm_renderer.max_renderers), true)
	$PopupMenu.add_check_item("Render", ITEM_RENDER_ENABLED)
	$PopupMenu.set_item_checked($PopupMenu.get_item_index(ITEM_RENDER_ENABLED), true)

func on_counter_change(count : int, pending : int) -> void:
	if count == 0 and pending == 0:
		$ProgressBar.max_value = 1
		$ProgressBar.value = 1
		$ProgressBar/Label.text = ""
		start_time = OS.get_ticks_msec()
	else:
		if count > last_value:
			if $ProgressBar.value == $ProgressBar.max_value:
				$ProgressBar.value = 0
				max_render_queue_size = 1
			else:
				max_render_queue_size += 1
		else:
			$ProgressBar.value += 1
		assert(max_render_queue_size-$ProgressBar.value == count)
		$ProgressBar.max_value = max_render_queue_size + pending
		if $ProgressBar.value > 0:
			var remaining_time_msec = (OS.get_ticks_msec()-start_time)*(count+pending)/$ProgressBar.value
			$ProgressBar/Label.text = "%d/%d - %d s" % [ $ProgressBar.value, $ProgressBar.max_value, remaining_time_msec/1000 ]
		else:
			$ProgressBar/Label.text = "%d/%d - ? s" % [ $ProgressBar.value, $ProgressBar.max_value ]
	last_value = count

func _process(_delta):
	var fps : float = Performance.get_monitor(Performance.TIME_FPS)
	$FpsCounter.text = "%.1f FPS " % fps
	if auto:
		if fps > 50.0:
			fast_counter += 1
			if fast_counter > 5:
				set_max_renderers(min(mm_renderer.max_renderers+1, 8))
		else:
			fast_counter = 0
			if fps < 20.0:
				set_max_renderers(1)

func set_max_renderers(max_renderers : int):
	if mm_renderer.max_renderers == max_renderers:
		return
	$PopupMenu.set_item_checked($PopupMenu.get_item_index(mm_renderer.max_renderers), false)
	mm_renderer.max_renderers = max_renderers
	$PopupMenu.set_item_checked($PopupMenu.get_item_index(mm_renderer.max_renderers), true)

func _on_PopupMenu_id_pressed(id):
	var index = $PopupMenu.get_item_index(id)
	match id:
		ITEM_AUTO:
			auto = ! $PopupMenu.is_item_checked(index)
			$PopupMenu.set_item_checked(index, auto)
		ITEM_RENDER_ENABLED:
			var b : bool = ! $PopupMenu.is_item_checked(index)
			$PopupMenu.set_item_checked(index, b)
			mm_renderer.enable_renderers(b)
		_:
			set_max_renderers(id)

func _on_RenderCounter_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed:
		$PopupMenu.rect_global_position = get_global_mouse_position()
		$PopupMenu.popup()
