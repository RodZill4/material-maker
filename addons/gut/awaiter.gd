extends Node

signal timeout
signal wait_started

var _wait_time := 0.0
var _wait_frames := 0
var _signal_to_wait_on = null

var _predicate_function_waiting_to_be_true = null
var _predicate_time_between := 0.0
var _predicate_time_between_elpased := 0.0

var _did_last_wait_timeout = false
var did_last_wait_timeout = false :
	get: return _did_last_wait_timeout
	set(val): push_error("Cannot set did_last_wait_timeout")

var _elapsed_time := 0.0
var _elapsed_frames := 0


func _physics_process(delta):
	if(_wait_time != 0.0):
		_elapsed_time += delta
		if(_elapsed_time >= _wait_time):
			_end_wait()

	if(_wait_frames != 0):
		_elapsed_frames += 1
		if(_elapsed_frames >= _wait_frames):
			_end_wait()

	if(_predicate_function_waiting_to_be_true != null):
		_predicate_time_between_elpased += delta
		if(_predicate_time_between_elpased >= _predicate_time_between):
			_predicate_time_between_elpased = 0.0
			var result = _predicate_function_waiting_to_be_true.call()
			if(typeof(result) == TYPE_BOOL and result):
				_end_wait()


func _end_wait():
	# Check for time before checking for frames so that the extra frames added
	# when waiting on a signal do not cause a false negative for timing out.
	if(_wait_time > 0):
		_did_last_wait_timeout = _elapsed_time >= _wait_time
	elif(_wait_frames > 0):
		_did_last_wait_timeout = _elapsed_frames >= _wait_frames

	if(_signal_to_wait_on != null and _signal_to_wait_on.is_connected(_signal_callback)):
		_signal_to_wait_on.disconnect(_signal_callback)

	_wait_time = 0.0
	_wait_frames = 0
	_signal_to_wait_on = null
	_predicate_function_waiting_to_be_true = null
	_elapsed_time = 0.0
	_elapsed_frames = 0
	timeout.emit()


const ARG_NOT_SET = '_*_argument_*_is_*_not_set_*_'
func _signal_callback(
		_arg1=ARG_NOT_SET, _arg2=ARG_NOT_SET, _arg3=ARG_NOT_SET,
		_arg4=ARG_NOT_SET, _arg5=ARG_NOT_SET, _arg6=ARG_NOT_SET,
		_arg7=ARG_NOT_SET, _arg8=ARG_NOT_SET, _arg9=ARG_NOT_SET):

	_signal_to_wait_on.disconnect(_signal_callback)
	# DO NOT _end_wait here.  For other parts of the test to get the signal that
	# was waited on, we have to wait for a couple more frames.  For example, the
	# signal_watcher doesn't get the signal in time if we don't do this.
	_wait_frames = 2

func wait_seconds(x):
	_did_last_wait_timeout = false
	_wait_time = x
	wait_started.emit()


func wait_frames(x):
	_did_last_wait_timeout = false
	_wait_frames = x
	wait_started.emit()


func wait_for_signal(the_signal, max_time):
	_did_last_wait_timeout = false
	the_signal.connect(_signal_callback)
	_signal_to_wait_on = the_signal
	_wait_time = max_time
	wait_started.emit()


func wait_until(predicate_function: Callable, max_time, time_between_calls:=0.0):
	_predicate_time_between = time_between_calls
	_predicate_function_waiting_to_be_true = predicate_function
	_predicate_time_between_elpased = 0.0
	_did_last_wait_timeout = false
	_wait_time = max_time
	wait_started.emit()


func is_waiting():
	return _wait_time != 0.0 || _wait_frames != 0
