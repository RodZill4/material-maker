var _is_return_override = false
var _is_defaults_override = false
var _is_call_override = false
var _method_meta : Dictionary = {}


var _lgr = GutUtils.get_logger()
var logger = _lgr :
	get: return _lgr
	set(val): _lgr = val

var return_val = null
var stub_target = null
var parameters = null # the parameter values to match method call on.
var stub_method = null
var call_super = false
var call_this = null

# Whether this is a stub for default parameter values as they are defined in
# the script, and not an overridden default value.
var is_script_default = false

var parameter_count = -1 :
	get():
		_lgr.deprecated("parameter count deprecated")
		return -1

# Default values for parameters.  This is used to store default values for
# scripts and to override those values.  I'm not sure if there is a need to
# override them anymore, since I think this was introduced for stubbing vararg
# methods, but you still can for now.  This value should only be used if
# is_defaults_override is true.
var parameter_defaults = []

const NOT_SET = '|_1_this_is_not_set_1_|'

func _init(target=null, method=null, _subpath=null):
	stub_target = target
	stub_method = method

	if(typeof(target) == TYPE_CALLABLE):
		stub_target = target.get_object()
		stub_method = target.get_method()
		parameters = target.get_bound_arguments()
		if(parameters.size() == 0):
			parameters = null
	elif(typeof(target) == TYPE_STRING):
		if(target.is_absolute_path()):
			stub_target = load(str(target))
		else:
			_lgr.warn(str(target, ' is not a valid path'))

	if(stub_target is PackedScene):
		stub_target = GutUtils.get_scene_script_object(stub_target)

	# this is used internally to stub default parameters for everything that is
	# doubled...or something.  Look for stub_defaults_from_meta for usage.  This
	# behavior is not to be used by end users.
	if(typeof(method) == TYPE_DICTIONARY):
		_method_meta = method
		_load_defaults_from_metadata(method)
		is_script_default = true


func _load_defaults_from_metadata(meta):
	stub_method = meta.name
	var values = meta.default_args.duplicate()
	while (values.size() < meta.args.size()):
		values.push_front(null)

	param_defaults(values)


func _get_method_meta():
	if(_method_meta == {} and typeof(stub_target) == TYPE_OBJECT):
		var found_meta = GutUtils.get_method_meta(stub_target, stub_method)
		if(found_meta != null):
			_method_meta = found_meta
	return _method_meta


# -------------------------
# Public
# -------------------------
func to_return(val):
	return_val = val
	call_super = false
	_is_return_override = true

	return self


func to_do_nothing():
	to_return(null)
	return self


func to_call_super():
	call_super = true
	_is_call_override = true
	return self


func to_call(callable : Callable):
	call_this = callable
	_is_call_override = true
	return self


func when_passed(p1=NOT_SET,p2=NOT_SET,p3=NOT_SET,p4=NOT_SET,p5=NOT_SET,p6=NOT_SET,p7=NOT_SET,p8=NOT_SET,p9=NOT_SET,p10=NOT_SET):
	parameters = [p1,p2,p3,p4,p5,p6,p7,p8,p9,p10]
	var idx = 0
	while(idx < parameters.size()):
		if(str(parameters[idx]) == NOT_SET):
			parameters.remove_at(idx)
		else:
			idx += 1
	return self


func param_count(_x):
	_lgr.deprecated("Stubbing param_count is no longer required or supported.")
	return self


func param_defaults(values):
	var meta = _get_method_meta()
	if(meta != {} and meta.flags & METHOD_FLAG_VARARG):
		_lgr.error("Cannot stub defaults for methods with varargs.")
	else:
		parameter_defaults = values
		_is_defaults_override = true
	return self


func is_default_override_only():
	return is_defaults_override() and !is_return_override() and !is_call_override()


func is_return_override():
	return _is_return_override


func is_defaults_override():
	return _is_defaults_override


func is_call_override():
	return _is_call_override


func to_s():
	var base_string = str(stub_target, '.', stub_method)

	if(parameter_defaults.size() > 0):
		base_string += str(" defaults ", parameter_defaults)

	if(call_super):
		base_string += " to call SUPER"

	if(call_this != null):
		base_string += str(" to call ", call_this)

	if(parameters != null):
		base_string += str(' with params (', parameters, ') returns ', return_val)
	else:
		base_string += str(' returns ', return_val)

	return base_string
