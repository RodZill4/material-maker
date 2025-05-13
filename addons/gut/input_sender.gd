class_name GutInputSender
## The InputSender class.  It sends input to places.
##
## This is the full description that has not yet been filled in.

# Implemented InputEvent* convenience methods
# 	InputEventAction
# 	InputEventKey
# 	InputEventMouseButton
#	InputEventMouseMotion

# Yet to implement InputEvents
# 	InputEventJoypadButton
# 	InputEventJoypadMotion
# 	InputEventMagnifyGesture
# 	InputEventMIDI
# 	InputEventPanGesture
# 	InputEventScreenDrag
# 	InputEventScreenTouch



# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
class InputQueueItem:
	extends Node

	var events = []
	var time_delay = null
	var frame_delay = null
	var _waited_frames = 0
	var _is_ready = false
	var _delay_started = false

	signal event_ready

	# TODO should this be done in _physics_process instead or should it be
	# configurable?
	func _physics_process(delta):
		if(frame_delay > 0 and _delay_started):
			_waited_frames += 1
			if(_waited_frames >= frame_delay):
				event_ready.emit()

	func _init(t_delay,f_delay):
		time_delay = t_delay
		frame_delay = f_delay
		_is_ready = time_delay == 0 and frame_delay == 0

	func _on_time_timeout():
		_is_ready = true
		event_ready.emit()

	func _delay_timer(t):
		return Engine.get_main_loop().root.get_tree().create_timer(t)

	func is_ready():
		return _is_ready

	func start():
		_delay_started = true
		if(time_delay > 0):
			var t = _delay_timer(time_delay)
			t.connect("timeout",Callable(self,"_on_time_timeout"))




# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
class MouseDraw:
	extends Node2D

	var down_color = Color(1, 1, 1, .25)
	var up_color = Color(0, 0, 0, .25)
	var line_color = Color(1, 0, 0)
	var disabled = true :
		get : return disabled
		set(val) :
			disabled = val
			queue_redraw()

	var _draw_at = Vector2(0, 0)
	var _b1_down = false
	var _b2_down = false


	func draw_event(event):
		if(event is InputEventMouse):
			_draw_at = event.position
			if(event is InputEventMouseButton):
				if(event.button_index == MOUSE_BUTTON_LEFT):
					_b1_down = event.pressed
				elif(event.button_index == MOUSE_BUTTON_RIGHT):
					_b2_down = event.pressed
		queue_redraw()


	func _draw_cicled_cursor():
		var r = 10
		var b1_color = up_color
		var b2_color = up_color

		if(_b1_down):
			var pos = _draw_at - (Vector2(r * 1.5, 0))
			draw_arc(pos, r / 2, 0, 360, 180, b1_color)

		if(_b2_down):
			var pos = _draw_at + (Vector2(r * 1.5, 0))
			draw_arc(pos, r / 2, 0, 360, 180, b2_color)

		draw_arc(_draw_at, r, 0, 360, 360, line_color, 1)
		draw_line(_draw_at - Vector2(0, r), _draw_at + Vector2(0, r), line_color)
		draw_line(_draw_at - Vector2(r, 0), _draw_at + Vector2(r, 0), line_color)


	func _draw_square_cursor():
		var r = 10
		var b1_color = up_color
		var b2_color = up_color

		if(_b1_down):
			b1_color = down_color

		if(_b2_down):
			b2_color = down_color

		var blen = r * .75
		# left button rectangle
		draw_rect(Rect2(_draw_at - Vector2(blen, blen), Vector2(blen, blen * 2)), b1_color)
		# right button rectrangle
		draw_rect(Rect2(_draw_at - Vector2(0, blen), Vector2(blen, blen * 2)), b2_color)
		# Crosshair
		draw_line(_draw_at - Vector2(0, r), _draw_at + Vector2(0, r), line_color)
		draw_line(_draw_at - Vector2(r, 0), _draw_at + Vector2(r, 0), line_color)


	func _draw():
		if(disabled):
			return
		_draw_square_cursor()







# ##############################################################################
#
# ##############################################################################
var InputFactory = load("res://addons/gut/input_factory.gd")

const INPUT_WARN = 'If using Input as a reciever it will not respond to *_down events until a *_up event is recieved.  Call the appropriate *_up event or use hold_for(...) to automatically release after some duration.'

var _lgr = GutUtils.get_logger()
var _receivers = []
var _input_queue = []
var _next_queue_item = null

# used by hold_for and echo.
var _last_event = null
# indexed by keycode, each entry contains a boolean value indicating the
# last emitted "pressed" value for that keycode.
var _pressed_keys = {}
var _pressed_actions = {}
var _pressed_mouse_buttons = {}

var _auto_flush_input = false
var _tree_items_parent = null
var _mouse_draw = null;

var _default_mouse_position = {
	position = Vector2(0, 0),
	global_position = Vector2(0, 0)
}

var _last_mouse_position = {
}

## Warp mouse when sending INputEventMouse* events
var mouse_warp = false
var draw_mouse = true

signal idle


## You can pass in a receiver if you want to.
func _init(r=null):
	if(r != null):
		add_receiver(r)

	_last_mouse_position = _default_mouse_position.duplicate()
	_tree_items_parent = Node.new()
	Engine.get_main_loop().root.add_child(_tree_items_parent)

	_mouse_draw = MouseDraw.new()
	_tree_items_parent.add_child(_mouse_draw)
	_mouse_draw.disabled = false


func _notification(what):
	if(what == NOTIFICATION_PREDELETE):
		if(is_instance_valid(_tree_items_parent)):
			_tree_items_parent.queue_free()


func _add_queue_item(item):
	item.connect("event_ready", _on_queue_item_ready.bind(item))
	_next_queue_item = item
	_input_queue.append(item)
	_tree_items_parent.add_child(item)
	if(_input_queue.size() == 1):
		item.start()


func _handle_pressed_keys(event):
	if(event is InputEventKey):
		if((event.pressed and !event.echo) and is_key_pressed(event.keycode)):
			_lgr.warn(str("InputSender:  key_down called for ", event.as_text(), " when that key is already pressed.  ", INPUT_WARN))
		_pressed_keys[event.keycode] = event.pressed
	elif(event is InputEventAction):
		if(event.pressed and is_action_pressed(event.action)):
			_lgr.warn(str("InputSender:  action_down called for ", event.action, " when that action is already pressed.  ", INPUT_WARN))
		_pressed_actions[event.action] = event.pressed
	elif(event is InputEventMouseButton):
		if(event.pressed and is_mouse_button_pressed(event.button_index)):
			_lgr.warn(str("InputSender:  mouse_button_down called for ", event.button_index, " when that mouse button is already pressed.  ", INPUT_WARN))
		_pressed_mouse_buttons[event.button_index] = event


func _handle_mouse_position(event):
	if(event is InputEventMouse):
		_mouse_draw.disabled = !draw_mouse
		_mouse_draw.draw_event(event)
		if(mouse_warp):
			DisplayServer.warp_mouse(event.position)


func _send_event(event):
	_handle_mouse_position(event)
	_handle_pressed_keys(event)

	for r in _receivers:
		if(r == Input):
			Input.parse_input_event(event)
			if(event is InputEventAction):
				if(event.pressed):
					Input.action_press(event.action)
				else:
					Input.action_release(event.action)
			if(_auto_flush_input):
				Input.flush_buffered_events()
		else:
			if(r.has_method(&"_input")):
				r._input(event)

			if(r.has_signal(&"gui_input")):
				r.gui_input.emit(event)

			if(r.has_method(&"_gui_input")):
				r._gui_input(event)

			if(r.has_method(&"_unhandled_input")):
				r._unhandled_input(event)


func _send_or_record_event(event):
	_last_event = event
	if(_next_queue_item != null):
		_next_queue_item.events.append(event)
	else:
		_send_event(event)


func _set_last_mouse_positions(event : InputEventMouse):
	_last_mouse_position.position = event.position
	_last_mouse_position.global_position = event.global_position


func _apply_last_position_and_set_last_position(event, position, global_position):
	event.position = GutUtils.nvl(position, _last_mouse_position.position)
	event.global_position = GutUtils.nvl(
		global_position, _last_mouse_position.global_position)
	_set_last_mouse_positions(event)


func _new_defaulted_mouse_button_event(position, global_position):
	var event = InputEventMouseButton.new()
	_apply_last_position_and_set_last_position(event, position, global_position)
	return event


func _new_defaulted_mouse_motion_event(position, global_position):
	var event = InputEventMouseMotion.new()
	_apply_last_position_and_set_last_position(event, position, global_position)
	for key in _pressed_mouse_buttons:
		if(_pressed_mouse_buttons[key].pressed):
			event.button_mask += key
	return event


# ------------------------------
# Events
# ------------------------------
func _on_queue_item_ready(item):
	for event in item.events:
		_send_event(event)

	var done_event = _input_queue.pop_front()
	done_event.queue_free()

	if(_input_queue.size() == 0):
		_next_queue_item = null
		idle.emit()
	else:
		_input_queue[0].start()


# ------------------------------
# Public
# ------------------------------
func add_receiver(obj):
	_receivers.append(obj)

func get_receivers():
	return _receivers

func is_idle():
	return _input_queue.size() == 0

func is_key_pressed(which):
	var event = InputFactory.key_up(which)
	return _pressed_keys.has(event.keycode) and _pressed_keys[event.keycode]

func is_action_pressed(which):
	return _pressed_actions.has(which) and _pressed_actions[which]

func is_mouse_button_pressed(which):
	return _pressed_mouse_buttons.has(which) and _pressed_mouse_buttons[which].pressed

func get_auto_flush_input():
	return _auto_flush_input

func set_auto_flush_input(val):
	_auto_flush_input = val


func wait(t):
	if(typeof(t) == TYPE_STRING):
		var suffix = t.substr(t.length() -1, 1)
		var val = t.rstrip('s').rstrip('f').to_float()

		if(suffix.to_lower() == 's'):
			wait_secs(val)
		elif(suffix.to_lower() == 'f'):
			wait_frames(val)
	else:
		wait_secs(t)

	return self


func clear():
	_last_event = null
	_next_queue_item = null

	for item in _input_queue:
		item.free()
	_input_queue.clear()

	_pressed_keys.clear()
	_pressed_actions.clear()
	_pressed_mouse_buttons.clear()
	_last_mouse_position = _default_mouse_position.duplicate()


# ------------------------------
# Event methods
# ------------------------------
func key_up(which):
	var event = InputFactory.key_up(which)
	_send_or_record_event(event)
	return self


func key_down(which):
	var event = InputFactory.key_down(which)
	_send_or_record_event(event)
	return self


func key_echo():
	if(_last_event != null and _last_event is InputEventKey):
		var new_key = _last_event.duplicate()
		new_key.echo = true
		_send_or_record_event(new_key)
	return self


func action_up(which, strength=1.0):
	var event  = InputFactory.action_up(which, strength)
	_send_or_record_event(event)
	return self


func action_down(which, strength=1.0):
	var event  = InputFactory.action_down(which, strength)
	_send_or_record_event(event)
	return self


func mouse_left_button_down(position=null, global_position=null):
	var event = _new_defaulted_mouse_button_event(position, global_position)
	event.pressed = true
	event.button_index = MOUSE_BUTTON_LEFT
	_send_or_record_event(event)
	return self


func mouse_left_button_up(position=null, global_position=null):
	var event = _new_defaulted_mouse_button_event(position, global_position)
	event.pressed = false
	event.button_index = MOUSE_BUTTON_LEFT
	_send_or_record_event(event)
	return self


func mouse_double_click(position=null, global_position=null):
	var event = InputFactory.mouse_double_click(position, global_position)
	event.double_click = true
	_send_or_record_event(event)
	return self


func mouse_right_button_down(position=null, global_position=null):
	var event = _new_defaulted_mouse_button_event(position, global_position)
	event.pressed = true
	event.button_index = MOUSE_BUTTON_RIGHT
	_send_or_record_event(event)
	return self


func mouse_right_button_up(position=null, global_position=null):
	var event = _new_defaulted_mouse_button_event(position, global_position)
	event.pressed = false
	event.button_index = MOUSE_BUTTON_RIGHT
	_send_or_record_event(event)
	return self


func mouse_motion(position, global_position=null):
	var event = _new_defaulted_mouse_motion_event(position, global_position)
	_send_or_record_event(event)
	return self


func mouse_relative_motion(offset, speed=Vector2(0, 0)):
	var last_event = _new_defaulted_mouse_motion_event(null, null)
	var event = InputFactory.mouse_relative_motion(offset, last_event, speed)
	_set_last_mouse_positions(event)
	_send_or_record_event(event)
	return self


func mouse_set_position(position, global_position=null):
	var event = _new_defaulted_mouse_motion_event(position, global_position)
	return self


func mouse_left_click_at(where, duration = '5f'):
	wait_frames(1)
	mouse_left_button_down(where)
	hold_for(duration)
	wait_frames(10)
	return self


func send_event(event):
	_send_or_record_event(event)
	return self


func release_all():
	for key in _pressed_keys:
		if(_pressed_keys[key]):
			_send_event(InputFactory.key_up(key))
	_pressed_keys.clear()

	for key in _pressed_actions:
		if(_pressed_actions[key]):
			_send_event(InputFactory.action_up(key))
	_pressed_actions.clear()

	for key in _pressed_mouse_buttons:
		var event = _pressed_mouse_buttons[key].duplicate()
		if(event.pressed):
			event.pressed = false
			_send_event(event)
	_pressed_mouse_buttons.clear()

	return self


func wait_frames(num_frames):
	var item = InputQueueItem.new(0, num_frames)
	_add_queue_item(item)
	return self


func wait_secs(num_secs):
	var item = InputQueueItem.new(num_secs, 0)
	_add_queue_item(item)
	return self


func hold_for(duration):
	if(_last_event != null and _last_event.pressed):
		var next_event = _last_event.duplicate()
		next_event.pressed = false

		wait(duration)
		send_event(next_event)
	return self


# ##############################################################################
#(G)odot (U)nit (T)est class
#
# ##############################################################################
# The MIT License (MIT)
# =====================
#
# Copyright (c) 2025 Tom "Butch" Wesley
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# ##############################################################################
# Description
# -----------
# This class sends input to one or more recievers.  The receivers' _input,
# _unhandled_input, and _gui_input are called sending InputEvent* events.
# InputEvents can be sent via the helper methods or a custom made InputEvent
# can be sent via send_event(...)
#
# ##############################################################################