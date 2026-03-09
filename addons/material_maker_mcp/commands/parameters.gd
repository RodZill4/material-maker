## parameters.gd — Parameter get/set command handlers for Material Maker MCP
##
## Handles reading and writing node parameters over the MCP bridge.
## Uses the real Material Maker API: MMGenGraph children accessed via
## get_current_graph_edit().generator, parameters via get_parameter_defs(),
## get_parameter(), and set_parameter().
##
## Written for Godot 4.x / Material Maker 1.4+.

extends RefCounted

var _main_window = null


func init(main_window) -> void:
	_main_window = main_window


# ---------------------------------------------------------------------------
# Graph / node lookup
# ---------------------------------------------------------------------------

## Returns the current MMGenGraph (data model) from the active graph editor.
func _get_graph():
	if _main_window == null:
		return null
	var graph_edit = _main_window.get_current_graph_edit()
	if graph_edit == null:
		return null
	return graph_edit.generator


## Finds a generator node (MMGenBase subclass) by its node ID within the
## current graph. Generator children are direct children of MMGenGraph.
func _find_node(node_id: String):
	var graph = _get_graph()
	if graph == null:
		return null
	return graph.get_node(NodePath(node_id))


# ---------------------------------------------------------------------------
# Public command handlers
# ---------------------------------------------------------------------------

## get_node_parameters — Return all parameter values and metadata for a node.
func get_node_parameters(params: Dictionary) -> Dictionary:
	if not params.has("node_id"):
		return _error("Missing required parameter: 'node_id'.")

	var node_id: String = str(params["node_id"])

	var node = _find_node(node_id)
	if node == null:
		return _error("Node not found: '%s'." % node_id)

	var defs: Array = node.get_parameter_defs()
	var parameters: Dictionary = {}

	for def_dict: Dictionary in defs:
		var pname: String = def_dict.get("name", "")
		if pname.is_empty():
			continue

		var ptype: String = str(def_dict.get("type", "unknown"))
		var value = node.get_parameter(pname)

		var entry: Dictionary = {
			"value": _serialize_value(value),
			"type": ptype,
		}

		if def_dict.has("label"):
			entry["label"] = def_dict["label"]
		if def_dict.has("shortdesc"):
			entry["shortdesc"] = def_dict["shortdesc"]
		if def_dict.has("longdesc"):
			entry["longdesc"] = def_dict["longdesc"]
		if def_dict.has("default"):
			entry["default"] = _serialize_value(def_dict["default"])
		if def_dict.has("min"):
			entry["min"] = def_dict["min"]
		if def_dict.has("max"):
			entry["max"] = def_dict["max"]
		if def_dict.has("step"):
			entry["step"] = def_dict["step"]
		if def_dict.has("control"):
			entry["control"] = def_dict["control"]
		if def_dict.has("values"):
			entry["values"] = def_dict["values"]

		parameters[pname] = entry

	return {
		"node_id": node_id,
		"parameters": parameters,
	}


## set_node_parameter — Set a single parameter on a node.
## set_parameter() triggers recompile/update automatically.
func set_node_parameter(params: Dictionary) -> Dictionary:
	if not params.has("node_id"):
		return _error("Missing required parameter: 'node_id'.")
	if not params.has("parameter"):
		return _error("Missing required parameter: 'parameter'.")
	if not params.has("value"):
		return _error("Missing required parameter: 'value'.")

	var node_id: String = str(params["node_id"])
	var parameter: String = str(params["parameter"])
	var new_value = params["value"]

	var node = _find_node(node_id)
	if node == null:
		return _error("Node not found: '%s'." % node_id)

	var def_dict = _get_parameter_def(node, parameter)
	if def_dict == null:
		return _error("Node '%s' has no parameter named '%s'." % [node_id, parameter])

	var old_value = node.get_parameter(parameter)
	var coerced_value = _coerce_value(def_dict, new_value)
	node.set_parameter(parameter, coerced_value)

	return {
		"node_id": node_id,
		"parameter": parameter,
		"old_value": _serialize_value(old_value),
		"new_value": _serialize_value(coerced_value),
	}


## set_multiple_parameters — Batch-set parameters across one or more nodes.
## Each call to set_parameter() triggers its own recompile internally.
func set_multiple_parameters(params: Dictionary) -> Dictionary:
	if not params.has("updates"):
		return _error("Missing required parameter: 'updates'.")

	var updates = params["updates"]
	if typeof(updates) != TYPE_ARRAY:
		return _error("'updates' must be an array.")

	var results: Array = []
	var updated_count: int = 0

	for i: int in range(updates.size()):
		var entry = updates[i]

		if typeof(entry) != TYPE_DICTIONARY:
			results.append({"index": i, "error": true, "message": "Entry %d is not a dictionary." % i})
			continue

		if not entry.has("node_id") or not entry.has("parameter") or not entry.has("value"):
			results.append({"index": i, "error": true, "message": "Entry %d missing node_id, parameter, or value." % i})
			continue

		var node_id: String = str(entry["node_id"])
		var parameter: String = str(entry["parameter"])
		var new_value = entry["value"]

		var node = _find_node(node_id)
		if node == null:
			results.append({"index": i, "error": true, "message": "Node not found: '%s'." % node_id})
			continue

		var def_dict = _get_parameter_def(node, parameter)
		if def_dict == null:
			results.append({"index": i, "error": true, "message": "Node '%s' has no parameter '%s'." % [node_id, parameter]})
			continue

		var old_value = node.get_parameter(parameter)
		var coerced_value = _coerce_value(def_dict, new_value)
		node.set_parameter(parameter, coerced_value)
		updated_count += 1

		results.append({
			"index": i,
			"node_id": node_id,
			"parameter": parameter,
			"old_value": _serialize_value(old_value),
			"new_value": _serialize_value(coerced_value),
		})

	return {
		"updated": updated_count,
		"results": results,
	}


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Look up the definition dict for a specific parameter on a node.
func _get_parameter_def(node, pname: String):
	var defs: Array = node.get_parameter_defs()
	for d: Dictionary in defs:
		if d.get("name", "") == pname:
			return d
	return null


# ---------------------------------------------------------------------------
# Value coercion
# ---------------------------------------------------------------------------

## Coerce an incoming JSON value to the type expected by a parameter definition.
func _coerce_value(def_dict: Dictionary, value):
	var ptype: String = str(def_dict.get("type", ""))

	match ptype:
		"float":
			return float(value)

		"int", "size":
			return int(value)

		"boolean":
			if typeof(value) == TYPE_BOOL:
				return value
			if typeof(value) == TYPE_STRING:
				return value.to_lower() == "true"
			return bool(value)

		"enum":
			if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
				return int(value)
			if typeof(value) == TYPE_STRING:
				var values_list = def_dict.get("values", [])
				for i: int in range(values_list.size()):
					var opt = values_list[i]
					var opt_name: String = str(opt["name"]) if typeof(opt) == TYPE_DICTIONARY else str(opt)
					if opt_name.to_lower() == str(value).to_lower():
						return i
				if str(value).is_valid_int():
					return int(value)
			return int(value)

		"color":
			if typeof(value) == TYPE_COLOR:
				return value
			if typeof(value) == TYPE_DICTIONARY:
				return Color(
					float(value.get("r", 0.0)),
					float(value.get("g", 0.0)),
					float(value.get("b", 0.0)),
					float(value.get("a", 1.0)),
				)
			if typeof(value) == TYPE_STRING:
				return Color(value)
			return value

		"string":
			return str(value)

		"gradient", "curve", "polygon", "polyline", "splines", "pixels", "lattice":
			return value

		_:
			return value


# ---------------------------------------------------------------------------
# Value serialization
# ---------------------------------------------------------------------------

## Serialize a Godot value into a JSON-safe representation.
func _serialize_value(value) -> Variant:
	if value == null:
		return null

	match typeof(value):
		TYPE_COLOR:
			var c: Color = value as Color
			return {"r": c.r, "g": c.g, "b": c.b, "a": c.a}

		TYPE_VECTOR2:
			var v: Vector2 = value as Vector2
			return {"x": v.x, "y": v.y}

		TYPE_VECTOR3:
			var v: Vector3 = value as Vector3
			return {"x": v.x, "y": v.y, "z": v.z}

		TYPE_OBJECT:
			if value.has_method("serialize"):
				return value.serialize()
			return str(value)

		TYPE_DICTIONARY:
			var out: Dictionary = {}
			for key in value:
				out[str(key)] = _serialize_value(value[key])
			return out

		TYPE_ARRAY:
			var out: Array = []
			for item in value:
				out.append(_serialize_value(item))
			return out

		_:
			return value


# ---------------------------------------------------------------------------
# Error formatting
# ---------------------------------------------------------------------------

func _error(message: String) -> Dictionary:
	return {
		"error": true,
		"message": message,
	}
