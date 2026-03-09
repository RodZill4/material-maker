## utils.gd — Utility / escape-hatch command handlers for Material Maker MCP
##
## Handles `execute_mm_script` — an arbitrary GDScript execution tool modelled
## after Blender MCP's `execute_blender_code`. This is DISABLED by default and
## must be explicitly enabled in the MCP plugin configuration.
##
## WARNING: Enabling script execution allows any connected MCP client to run
## arbitrary code inside the Material Maker process. Only enable this on
## trusted, local-only connections. Never expose it on a network-accessible port.
##
## Written for Godot 4.x.

class_name UtilsCommands
extends RefCounted

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## The error message returned when script execution is disabled.
const DISABLED_MESSAGE: String = "execute_mm_script is disabled. Enable it in the MCP plugin configuration."

## Maximum allowed script length in characters, as a basic safety measure.
const MAX_SCRIPT_LENGTH: int = 50000

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Reference to the Material Maker main window, set via init().
var _main_window = null

## Whether execute_mm_script is enabled. Defaults to false (disabled).
## Must be explicitly set to true via configuration to allow script execution.
var script_execution_enabled: bool = false

# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------

## Called once after construction. Receives the MM main window so scripts
## can access the full application context.
func init(main_window) -> void:
	_main_window = main_window


## Enable or disable script execution. Called by the plugin based on its
## configuration (e.g. from an environment variable or config file).
func set_script_execution_enabled(enabled: bool) -> void:
	script_execution_enabled = enabled
	if enabled:
		push_warning("[MCP Utils] execute_mm_script has been ENABLED. This allows arbitrary code execution.")
	else:
		print("[MCP Utils] execute_mm_script is disabled.")

# ---------------------------------------------------------------------------
# execute_mm_script
# ---------------------------------------------------------------------------

## Execute arbitrary GDScript inside Material Maker using Godot's Expression
## class. This is the power-user escape hatch, mirroring Blender MCP's
## `execute_blender_code` tool.
##
## Params:
##   script  : String — The GDScript expression to evaluate.
##   context : String — Optional context hint (unused currently, reserved for
##                      future use such as selecting which node to bind as `self`).
##
## Returns:
##   On success: { "result": <evaluation result>, "output": <string representation> }
##   On failure: { "error": true, "message": "..." }
##
## IMPORTANT: This function is gated by the `script_execution_enabled` flag.
## If disabled, it returns an error without evaluating anything.
func execute_mm_script(params: Dictionary) -> Dictionary:
	# ------------------------------------------------------------------
	# Gate: check if script execution is enabled
	# ------------------------------------------------------------------
	if not script_execution_enabled:
		return _error(DISABLED_MESSAGE)

	# ------------------------------------------------------------------
	# Validate params
	# ------------------------------------------------------------------
	if not params.has("script") or str(params["script"]).strip_edges().is_empty():
		return _error("Missing required parameter: script")

	var script_text: String = str(params["script"]).strip_edges()
	var context: String = str(params.get("context", "")).strip_edges()

	# Basic length check to prevent absurdly large inputs.
	if script_text.length() > MAX_SCRIPT_LENGTH:
		return _error("Script exceeds maximum length of %d characters." % MAX_SCRIPT_LENGTH)

	# ------------------------------------------------------------------
	# Execute via Godot's Expression class
	# ------------------------------------------------------------------
	# The Expression class parses and evaluates a single GDScript expression.
	# It does NOT support multi-line statements, control flow (if/for/while),
	# or variable declarations. For those, the user would need a different
	# approach (e.g. loading a full GDScript resource).
	#
	# We pass the main_window as the base instance so the expression can
	# call methods and access properties on it.
	#
	# Available input names allow the script to reference useful objects:
	#   - main_window: the MM main window node
	#   - graph_edit:  the currently active graph editor (may be null)
	#
	# TODO: Consider whether to also expose mm_globals or the project tree
	# as additional input variables for more convenient scripting.

	var expression := Expression.new()

	# Define input variable names the expression can reference.
	var input_names: PackedStringArray = PackedStringArray(["main_window", "graph_edit"])

	# Gather input values.
	var graph_edit = null
	if _main_window != null and _main_window.has_method("get_current_graph_edit"):
		graph_edit = _main_window.get_current_graph_edit()

	var input_values: Array = [_main_window, graph_edit]

	# Parse the expression.
	var parse_err: Error = expression.parse(script_text, input_names)
	if parse_err != OK:
		return _error("Script parse error: %s" % expression.get_error_text())

	# Execute the expression with the main_window as the base instance.
	# This means unqualified method/property access resolves against main_window.
	var result = expression.execute(input_values, _main_window, true)

	# Check for runtime errors.
	if expression.has_execute_failed():
		return _error("Script execution error: %s" % expression.get_error_text())

	# ------------------------------------------------------------------
	# Build the response
	# ------------------------------------------------------------------
	# Convert the result to a JSON-safe representation. Not all Godot types
	# are directly serializable, so we convert to string as a fallback.
	var result_for_json = _make_json_safe(result)
	var output_str: String = str(result) if result != null else ""

	return {
		"result": result_for_json,
		"output": output_str,
	}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Attempt to convert a Godot Variant to a JSON-compatible value.
## Primitives (bool, int, float, string, null) pass through. Arrays and
## Dictionaries are recursively converted. Everything else becomes a string.
func _make_json_safe(value) -> Variant:
	if value == null:
		return null

	match typeof(value):
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		TYPE_ARRAY:
			var safe_array: Array = []
			for item in value:
				safe_array.append(_make_json_safe(item))
			return safe_array
		TYPE_DICTIONARY:
			var safe_dict: Dictionary = {}
			for key in value.keys():
				safe_dict[str(key)] = _make_json_safe(value[key])
			return safe_dict
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return { "x": value.x, "y": value.y }
		TYPE_VECTOR3, TYPE_VECTOR3I:
			return { "x": value.x, "y": value.y, "z": value.z }
		TYPE_COLOR:
			return { "r": value.r, "g": value.g, "b": value.b, "a": value.a }
		TYPE_PACKED_STRING_ARRAY:
			var arr: Array = []
			for s in value:
				arr.append(s)
			return arr
		_:
			# Fallback: convert to string representation.
			return str(value)


## Construct a standardised error dictionary.
func _error(message: String) -> Dictionary:
	return { "error": true, "message": message }
