var thepath = ''
var subpath = ''
var from_singleton = null
var is_partial = null

var double_ref : WeakRef = null
var stubber_ref : WeakRef = null
var spy_ref : WeakRef = null
var gut_ref : WeakRef = null

const NO_DEFAULT_VALUE = '!__gut__no__default__value__!'
func _init(double = null):
	if(double != null):
		var values = double.__gutdbl_values
		double_ref = weakref(double)
		thepath = values.thepath
		subpath = values.subpath
		stubber_ref = weakref_from_id(values.stubber)
		spy_ref = weakref_from_id(values.spy)
		gut_ref = weakref_from_id(values.gut)
		from_singleton = values.from_singleton
		is_partial = values.is_partial

		if(gut_ref.get_ref() != null):
			gut_ref.get_ref().get_autofree().add_free(double_ref.get_ref())


func _get_stubbed_method_to_call(method_name, called_with):
	var method = stubber_ref.get_ref().get_call_this(double_ref.get_ref(), method_name, called_with)
	if(method != null):
		method = method.bindv(called_with)
		return method
	return method


func weakref_from_id(inst_id):
	if(inst_id ==  -1):
		return weakref(null)
	else:
		return weakref(instance_from_id(inst_id))


func is_stubbed_to_call_super(method_name, called_with):
	if(stubber_ref.get_ref() != null):
		return stubber_ref.get_ref().should_call_super(double_ref.get_ref(), method_name, called_with)
	else:
		return false


func handle_other_stubs(method_name, called_with):
	if(stubber_ref.get_ref() == null):
		return

	var method = _get_stubbed_method_to_call(method_name, called_with)
	if(method != null):
		return await method.call()
	else:
		return stubber_ref.get_ref().get_return(double_ref.get_ref(), method_name, called_with)


func spy_on(method_name, called_with):
	if(spy_ref.get_ref() != null):
		spy_ref.get_ref().add_call(double_ref.get_ref(), method_name, called_with)


func default_val(method_name, p_index):
	if(stubber_ref.get_ref() == null):
		return null
	else:
		return stubber_ref.get_ref().get_default_value(double_ref.get_ref(), method_name, p_index)
