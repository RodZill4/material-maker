extends Control

var last_value : int = 0
var start_time : int = 0
var max_render_queue_size : int = 0

func _ready() -> void:
	pass # Replace with function body.

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

func _process(delta):
	$FpsCounter.text = "%.1f FPS " % Performance.get_monitor(Performance.TIME_FPS)
