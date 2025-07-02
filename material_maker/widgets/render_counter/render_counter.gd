extends Control


var start_time : int = 0
var max_render_queue_size : int = 0

var auto : bool = true
var fast_counter : int = 0

@onready var menu : PopupMenu = $PopupMenu
@onready var renderers_menu : PopupMenu = $PopupMenu/Renderers
@onready var render_menu : PopupMenu = $PopupMenu/MaxRenderSize
@onready var buffers_menu : PopupMenu = $PopupMenu/MaxBufferSize


const ITEM_AUTO : int                       = 1000
const ITEM_RENDER_ENABLED : int             = 1001
const ITEM_MATERIAL_STATS : int             = 1002
const ITEM_TRIGGER_DEPENDENCY_MANAGER : int = 1003


func _ready() -> void:
	menu.add_check_item("Render", ITEM_RENDER_ENABLED)
	menu.set_item_checked(menu.get_item_index(ITEM_RENDER_ENABLED), true)
	if mm_renderer.total_renderers > 1:
		menu.add_check_item("Auto", ITEM_AUTO)
		menu.set_item_checked(menu.get_item_index(ITEM_AUTO), true)
		# Renderers menu
		menu.add_submenu_item("Renderers", "Renderers")
		for i in range(mm_renderer.total_renderers):
			renderers_menu.add_radio_check_item("%d" % (i+1), i+1)
		renderers_menu.set_item_checked(renderers_menu.get_item_index(mm_renderer.max_renderers), true)
	menu.add_separator()
	# Render size limit menu
	menu.add_submenu_item("Maximum render size", "MaxRenderSize")
	var render_size = mm_globals.get_config("max_viewport_size")
	for i in range(4):
		var item_render_size : int = 512 << i
		render_menu.add_radio_check_item("%dx%d" % [ item_render_size, item_render_size ], item_render_size)
	mm_renderer.max_viewport_size = render_size
	render_menu.set_item_checked(render_menu.get_item_index(render_size), true)
	# Buffer size limit menu
	menu.add_submenu_item("Maximum buffer size", "MaxBufferSize")
	buffers_menu.add_radio_check_item("Unlimited", 0)
	for i in range(7):
		var item_buffer_size : int = 32 << i
		buffers_menu.add_radio_check_item("%dx%d" % [ item_buffer_size, item_buffer_size ], item_buffer_size)
	buffers_menu.set_item_checked(buffers_menu.get_item_index(0), true)
	if OS.is_debug_build():
		menu.add_separator()
		menu.add_item("Material stats", ITEM_MATERIAL_STATS)
		menu.add_item("Trigger dependency manager", ITEM_TRIGGER_DEPENDENCY_MANAGER)
	# GPU RAM tooltip
	$GpuRam.tooltip_text = "Adapter: %s\nVendor: %s" % [ RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor() ]

func on_counter_change(count : int, pending : int) -> void:
	if pending == 0:
		$ProgressBar.max_value = 1
		$ProgressBar.value = 1
		$ProgressBar/Label.text = ""
	else:
		if count == pending:
			$ProgressBar.max_value = count
			start_time = Time.get_ticks_msec()
			$ProgressBar/Label.text = "%d/%d - ? s" % [ 0, pending ]
		else:
			var remaining_time_msec = (Time.get_ticks_msec()-start_time)*pending/(count-pending)
			$ProgressBar/Label.text = "%d/%d - %d s" % [ count-pending, count, remaining_time_msec/1000 ]
		$ProgressBar.value = count-pending

func e3tok(value : float) -> String:
	var unit_modifier : String = ""
	if value > 100000000:
		value *= 0.000000001
		unit_modifier = "G"
	elif value > 100000:
		value *= 0.000001
		unit_modifier = "M"
	elif value > 100:
		value *= 0.001
		unit_modifier = "k"
	return "%.1f %sb " % [ value, unit_modifier ]

func _process(_delta):
	var fps : float = Performance.get_monitor(Performance.TIME_FPS)
	$FpsCounter.text = "%.1f FPS " % fps
	if auto and mm_renderer.total_renderers > 1:
		if fps > 50.0:
			fast_counter += 1
			if fast_counter > 5:
				set_max_renderers(int(min(mm_renderer.max_renderers+1, mm_renderer.total_renderers)))
		else:
			fast_counter = 0
			if fps < 20.0:
				set_max_renderers(1)

func _on_MemUpdateTimer_timeout():
	$GpuRam.text = e3tok(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	var tooltip : String = "Adapter: %s\nVendor: %s" % [ RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor() ]
	tooltip += "\nVideo mem.: "+e3tok(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	tooltip += "\nBuffer mem.: "+e3tok(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED))
	# todo tooltip += "\nVertex mem.: "+e3tok(Performance.get_monitor(Performance.RENDER_VERTEX_MEM_USED))
	$GpuRam.tooltip_text = tooltip

func set_max_renderers(max_renderers : int):
	if mm_renderer.max_renderers == max_renderers:
		return
	renderers_menu.set_item_checked(renderers_menu.get_item_index(mm_renderer.max_renderers), false)
	mm_renderer.set_max_renderers(max_renderers)
	renderers_menu.set_item_checked(renderers_menu.get_item_index(mm_renderer.max_renderers), true)

func _on_PopupMenu_id_pressed(id):
	var index = menu.get_item_index(id)
	match id:
		ITEM_AUTO:
			auto = ! menu.is_item_checked(index)
			menu.set_item_checked(index, auto)
		ITEM_RENDER_ENABLED:
			var b : bool = ! menu.is_item_checked(index)
			menu.set_item_checked(index, b)
			mm_renderer.enable_renderers(b)
		ITEM_MATERIAL_STATS:
			var generator = mm_globals.main_window.get_current_graph_edit().top_generator
			print("Buffers: "+str(count_buffers(generator)))
			mm_deps.print_stats()
		ITEM_TRIGGER_DEPENDENCY_MANAGER:
			mm_deps.update()

func count_buffers(generator) -> int:
	var buffers = 0
	for c in generator.get_children():
		if c.get_type() == "buffer":
			buffers += 1
		elif c.get_type() == "iterate_buffer":
			buffers += 1
			print("iterate_buffer: "+str(c.parameters["iterations"]))
		elif c.get_type() == "graph":
			buffers += count_buffers(c)
	return buffers

func _on_Renderers_id_pressed(id):
	set_max_renderers(id)

func _on_MaxRenderSize_id_pressed(id):
	render_menu.set_item_checked(render_menu.get_item_index(mm_renderer.max_viewport_size), false)
	mm_renderer.max_viewport_size = id
	render_menu.set_item_checked(render_menu.get_item_index(id), true)
	mm_globals.set_config("max_viewport_size", id)

func _on_MaxBufferSize_id_pressed(id):
	if mm_renderer.max_buffer_size == id:
		return
	buffers_menu.set_item_checked(buffers_menu.get_item_index(mm_renderer.max_buffer_size), false)
	mm_renderer.max_buffer_size = id
	buffers_menu.set_item_checked(buffers_menu.get_item_index(mm_renderer.max_buffer_size), true)

func _on_RenderCounter_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		menu.position = get_screen_transform() * get_local_mouse_position()
		menu.popup()
