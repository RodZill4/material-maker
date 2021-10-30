extends UndoAction
class_name ParameterChangeUndoAction

var generator
var parameter_name
var new_value
var previous_value


func do():
	generator.set_parameter(parameter_name, new_value)
	pass
func undo():
	generator.set_parameter(parameter_name, previous_value)
	pass
