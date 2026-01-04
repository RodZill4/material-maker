class_name GutTrackedError
## This contains all the information provided by Godot about an error.
## This is also used to represent a GUT error.  See [Logger] for
## additional information about properties.  Some properties are not populated
## for GUT errors.

## This will be an [code]Array[ScriptBacktrace][/code] for engine/push errors.
## This will the result of [code]get_stack[/code] for GUT errors.
var backtrace = []
## Usually the description
var code = GutUtils.NO_TEST
var rationale = GutUtils.NO_TEST
## [enum Logger.ErrorType] value or, for GUT errors, this will be [code skip-lint]GutUtils.GUT_ERROR_TYPE[/code].
var error_type = -1
var editor_notify = false

## The full path to the file where the error occurred.
var file = GutUtils.NO_TEST
## The function name in [member file] where the error occurred.
var function = GutUtils.NO_TEST
## The line number in [member file]
var line = -1

## Used by GUT to flag errors as being handled.  This is set by various asserts
## or can be set in a test.  When set to [code]true[/code] GUT will ignore it
## when determining if an unexpected error occurred during the execution of the
## test.  Setting this value prior to performing any of the error related
## asserts may have unexpected results.  It is recommended you either set this
## manually or use the error asserts.
var handled = false


## _to_string that is not _to_string.
func to_s() -> String:
	return str("CODE:", code, " TYPE:", error_type, " RATIONALE:", rationale, "\n",
		file, '->', function, '@', line, "\n",
		backtrace, "\n")


## Returns [code]true[/code] if the error is a push_error.
func is_push_error():
	return error_type != GutUtils.GUT_ERROR_TYPE and function == "push_error"


## Returns [code]true[/code] if the error is an engine error.  This includes
## all errors that pass through the [Logger] that do not originate from the
## [code]push_error[/code] function.
func is_engine_error():
	return error_type != GutUtils.GUT_ERROR_TYPE and !is_push_error()


## Returns [code]true[/code] if the error is a GUT error.  Some fields may not
## be populated for GUT errors.
func is_gut_error():
	return error_type == GutUtils.GUT_ERROR_TYPE


func contains_text(text):
	return code.to_lower().find(text.to_lower()) != -1 or \
		rationale.to_lower().find(text.to_lower()) != -1


## For display purposes only, the actual value returned may change over time.
## This returns a name for the error_type as far as this class is concerned.
## Use the various [code]is_[/code] methods to check if an error is a certain
## type.
func get_error_type_name():
	var to_return = "Unknown"

	if(is_gut_error()):
		to_return =  "GUT"
	elif(is_push_error()):
		to_return = "push_error"
	elif(is_engine_error()):
		to_return = str("engine-", error_type)

	return to_return


# this might not work in other languages, and feels falkey, but might be
# useful at some point.
# func is_assert():
# 	return error_type == Logger.ERROR_TYPE_SCRIPT and \
# 		(code.find("Assertion failed.") == 0 or \
# 			code.find("Assertion failed:") == 0)