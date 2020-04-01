extends Node2D

var notes : Dictionary = {}

const WHITE = [0, 2, 4, 5, 7, 9, 11]
const BLACK = [1, 3, -1, 6, 8, 10, -1]

func _draw():
	for i in range(52):
		var color : Color = Color(1.0, 1.0, 1.0)
		var index : int = WHITE[(i+5)%7]+12*((i+5)/7)
		if notes.has(index):
			color = Color(0.8, 0.8, 1.0)
		draw_rect(Rect2(i*9, 0, 8, 30), color)
	for i in range(51):
		if BLACK[(i-2)%7] >= 0:
			var color : Color = Color(0.0, 0.0, 0.0)
			var index : int = BLACK[(i+5)%7]+12*((i+5)/7)
			if notes.has(index):
				color = Color(0.0, 0.0, 1.0)
			draw_rect(Rect2(i*9+6, 0, 5, 15), color) 

func process_midi_event(event):
	match event.message:
		9:
			notes[event.pitch] = { velocity=event.velocity, start=OS.get_ticks_usec() }
			update()
		8:
			notes[event.pitch].released = true
