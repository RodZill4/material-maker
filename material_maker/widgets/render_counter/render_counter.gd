extends Control

var last_value : int = 0
var start_time : int = 0

func _ready() -> void:
	pass # Replace with function body.

func on_counter_change(count : int) -> void:
	if count == 0:
		$ProgressBar.max_value = 1
		$ProgressBar.value = 1
		$ProgressBar/Label.text = ""
		start_time = OS.get_ticks_msec()
	else:
		if count > last_value:
			if $ProgressBar.value == $ProgressBar.max_value:
				$ProgressBar.value = 0
				$ProgressBar.max_value = 1
			else:
				$ProgressBar.max_value += 1
		else:
			$ProgressBar.value += 1
		assert($ProgressBar.max_value-$ProgressBar.value == count)
		if $ProgressBar.value > 0:
			var remaining_time_msec = (OS.get_ticks_msec()-start_time)*count/$ProgressBar.value
			$ProgressBar/Label.text = "%d/%d - %d s" % [ $ProgressBar.value, $ProgressBar.max_value, remaining_time_msec/1000 ]
		else:
			$ProgressBar/Label.text = "%d/%d - ? s" % [ $ProgressBar.value, $ProgressBar.max_value ]
	last_value = count

func _process(delta):
	$FpsCounter.text = "%.1f FPS " % Performance.get_monitor(Performance.TIME_FPS)
