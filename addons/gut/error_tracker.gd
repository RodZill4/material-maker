extends Logger
class_name GutErrorTracker

# ------------------------------------------------------------------------------
# Static methods wrap around add/remove logger to make disabling the logger
# easier and to help avoid misusing add/remove in tests.  If GUT needs to
# add/remove a logger then this is how it should do it.
# ------------------------------------------------------------------------------
static var registered_loggers := {}
static var register_loggers = true

static func register_logger(which):
	if(register_loggers and !registered_loggers.has(which)):
		OS.add_logger(which)
		registered_loggers[which] = get_stack()


static func deregister_logger(which):
	if(registered_loggers.has(which)):
		OS.remove_logger(which)
		registered_loggers.erase(which)




# ------------------------------------------------------------------------------
# GutErrorTracker
# ------------------------------------------------------------------------------
var _current_test_id = GutUtils.NO_TEST
var _mutex = Mutex.new()

var errors = GutUtils.OneToMany.new()

var treat_gut_errors_as : GutUtils.TREAT_AS = GutUtils.TREAT_AS.FAILURE
var treat_engine_errors_as : GutUtils.TREAT_AS = GutUtils.TREAT_AS.FAILURE
var treat_push_error_as : GutUtils.TREAT_AS = GutUtils.TREAT_AS.FAILURE
var disabled = false


# ----------------
#region Private
# ----------------

func _get_stack_data(current_test_name):
	var test_entry = {}
	var stackTrace = get_stack()

	if(stackTrace!=null):
		var index = 0
		while(index < stackTrace.size() and test_entry == {}):
			var line = stackTrace[index]
			var function = line.get("function")
			if function == current_test_name:
				test_entry = stackTrace[index]
			else:
				index += 1

		for i in range(index):
			stackTrace.remove_at(0)

	return {
		"test_entry" = test_entry,
		"full_stack" = stackTrace
	}


func _is_error_failable(error : GutTrackedError):
	var is_it = false
	if(error.handled == false):
		if(error.is_gut_error()):
			is_it = treat_gut_errors_as == GutUtils.TREAT_AS.FAILURE
		elif(error.is_push_error()):
			is_it = treat_push_error_as == GutUtils.TREAT_AS.FAILURE
		elif(error.is_engine_error()):
			is_it = treat_engine_errors_as == GutUtils.TREAT_AS.FAILURE
	return is_it

# ----------------
#endregion
#region Godot's Logger Overrides
# ----------------

# Godot's Logger virtual method for errors
func _log_error(function: String, file: String, line: int,
	code: String, rationale: String, editor_notify: bool,
	error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:

		add_error(function, file, line,
			code, rationale, editor_notify,
			error_type, script_backtraces)

# Godot's Logger virtual method for any output?
# func _log_message(message: String, error: bool) -> void:
# 	pass

# ----------------
#endregion
#region Public
# ----------------

func start_test(test_id):
	_current_test_id = test_id


func end_test():
	_current_test_id = GutUtils.NO_TEST


func did_test_error(test_id=_current_test_id):
	return errors.size(test_id) > 0


func get_current_test_errors():
	return errors.items.get(_current_test_id, [])


# This should look through all the errors for a test and see if a failure
# should happen based off of flags.
func should_test_fail_from_errors(test_id = _current_test_id):
	var to_return = false
	if(errors.items.has(test_id)):
		var errs = errors.items[test_id]
		var index = 0
		while(index < errs.size() and !to_return):
			var error = errs[index]
			to_return = _is_error_failable(error)
			index += 1
	return to_return


func get_errors_for_test(test_id=_current_test_id):
	var to_return = []
	if(errors.items.has(test_id)):
		to_return = errors.items[test_id].duplicate()

	return to_return


# Returns emtpy string or text for errors that occurred during the test that
# should cause failure based on this class' flags.
func get_fail_text_for_errors(test_id=_current_test_id) -> String:
	var error_texts = []

	if(errors.items.has(test_id)):
		for error in errors.items[test_id]:
			if(_is_error_failable(error)):
				error_texts.append(str('<', error.get_error_type_name(), '>', error.code))

	var to_return = ""
	for i in error_texts.size():
		if(to_return != ""):
			to_return += "\n"
		to_return += str("[", i + 1, "] ", error_texts[i])

	return to_return


func add_gut_error(text) -> GutTrackedError:
	if(_current_test_id != GutUtils.NO_TEST):
		var data = _get_stack_data(_current_test_id)
		if(data.test_entry != {}):
			return add_error(_current_test_id, data.test_entry.source, data.test_entry.line,
				text, '', false,
				GutUtils.GUT_ERROR_TYPE, data.full_stack)

	return add_error(_current_test_id, "unknown", -1,
		text, '', false,
		GutUtils.GUT_ERROR_TYPE, get_stack())


func add_error(function: String, file: String, line: int,
	code: String, rationale: String, editor_notify: bool,
	error_type: int, script_backtraces: Array) -> GutTrackedError:
		if(disabled):
			return

		_mutex.lock()

		var err := GutTrackedError.new()
		err.backtrace = script_backtraces
		err.code = code
		err.rationale = rationale
		err.error_type = error_type
		err.editor_notify = editor_notify
		err.file = file
		err.function = function
		err.line = line

		errors.add(_current_test_id, err)

		_mutex.unlock()

		return err
