extends Node
class_name MMLogger

var logger : Object = null

func set_logger(l : Object):
	logger = l

# Called when the node enters the scene tree for the first time.
func write(l: String, m : String):
	if logger:
		logger.write(l, m)
	elif l == "":
		print(m)
	else:
		print(l+": "+m)

func debug(m : String):
	write("DEBUG", m)

func message(m : String):
	write("", m)

func warning(m : String):
	write("WARNING", m)

func error(m : String):
	write("ERROR", m)
