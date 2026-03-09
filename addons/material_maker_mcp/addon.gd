## addon.gd — Material Maker MCP TCP Server Plugin
##
## This is the main plugin file for the Material Maker MCP bridge. It runs a
## lightweight TCP socket server inside Material Maker, accepting newline-delimited
## JSON commands from the Python MCP server (or any compatible client) and
## dispatching them to the appropriate command handlers.
##
## Architecture:
##   [Claude / AI Client] <--MCP/stdio--> [Python MCP Server] <--TCP:9002--> [This Plugin]
##
## Material Maker plugins extend Node (NOT EditorPlugin). They are loaded by
## MM's own Plugin Manager, not by the Godot editor plugin system.
##
## Written for Godot 4.x. Godot 3.x compatibility notes are included inline
## where the APIs diverge.

extends Node

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Default TCP port. Avoids conflict with Blender MCP which uses 9001.
const DEFAULT_PORT: int = 9002

## Maximum bytes to read from a client per _process tick. Keeps the main
## thread responsive even if a client sends a large payload.
const MAX_READ_BYTES_PER_TICK: int = 65536

## Protocol version — sent in handshake so the Python side can detect
## incompatibilities early.
const PROTOCOL_VERSION: String = "0.1.0"

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## The TCP server instance.
## Godot 4: TCPServer   |   Godot 3: TCP_Server (note the underscore)
var _server: TCPServer = null

## Currently connected clients. We support multiple simultaneous connections
## (e.g. one from the MCP server and one from a debug tool).
## Each entry maps a StreamPeerTCP to its per-client state dictionary.
var _clients: Dictionary = {}

## The port the server is actually listening on (after startup).
var _port: int = DEFAULT_PORT

## Command handler modules — instantiated in _ready().
var _scene_commands: RefCounted = null
var _graph_commands: RefCounted = null
var _parameter_commands: RefCounted = null
var _export_commands: RefCounted = null
var _utils_commands: RefCounted = null

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Read port from environment variable, falling back to the default.
	# The Python MCP server passes this via env so both sides agree.
	var env_port: String = OS.get_environment("MM_MCP_PORT")
	if env_port != "" and env_port.is_valid_int():
		_port = env_port.to_int()

	# Initialize command handler modules.
	# mm_globals is an autoload that holds a reference to the real MainWindow.
	# We must wait a frame for autoloads and the main scene to be ready.
	await get_tree().process_frame
	var main_window = get_node("/root/mm_globals").main_window
	if main_window == null:
		push_error("[MCP] Could not find Material Maker main window. MCP server will not start.")
		return

	_scene_commands = preload("res://addons/material_maker_mcp/commands/scene.gd").new()
	_scene_commands.init(main_window)
	_graph_commands = preload("res://addons/material_maker_mcp/commands/graph.gd").new()
	_graph_commands.init(main_window)
	_parameter_commands = preload("res://addons/material_maker_mcp/commands/parameters.gd").new()
	_parameter_commands.init(main_window)
	_export_commands = preload("res://addons/material_maker_mcp/commands/export.gd").new()
	_export_commands.init(main_window)
	_utils_commands = preload("res://addons/material_maker_mcp/commands/utils.gd").new()
	_utils_commands.init(main_window)

	_server = TCPServer.new()

	# Godot 4: listen() returns an Error enum.
	# Godot 3: listen() also returns an Error but the class is TCP_Server.
	var err: Error = _server.listen(_port, "127.0.0.1")
	if err != OK:
		push_error("[MCP] Failed to start TCP server on port %d (Error %d)" % [_port, err])
		print("[MCP] ERROR: Could not bind to port %d — is another instance running?" % _port)
		return

	print("[MCP] Server listening on 127.0.0.1:%d  (protocol v%s)" % [_port, PROTOCOL_VERSION])


func _exit_tree() -> void:
	# Clean shutdown: disconnect every client, then stop the server.
	print("[MCP] Shutting down server...")

	for peer: StreamPeerTCP in _clients.keys():
		peer.disconnect_from_host()
	_clients.clear()

	if _server != null:
		_server.stop()
		_server = null

	print("[MCP] Server stopped.")


# ---------------------------------------------------------------------------
# Main loop — runs every frame
# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if _server == null:
		return

	# ------------------------------------------------------------------
	# Accept new connections
	# ------------------------------------------------------------------
	# Godot 4: is_connection_available() / take_connection()
	# Godot 3: is_connection_available() / take_connection() — same API
	while _server.is_connection_available():
		var peer: StreamPeerTCP = _server.take_connection()
		if peer != null:
			# Disable Nagle's algorithm for lower latency on small JSON messages.
			peer.set_no_delay(true)
			# Initialise per-client state with an empty receive buffer.
			_clients[peer] = {
				"buffer": ""  # Accumulates partial reads until we see a newline.
			}
			print("[MCP] Client connected (%d total)." % _clients.size())

	# ------------------------------------------------------------------
	# Read from existing clients
	# ------------------------------------------------------------------
	# We iterate over a snapshot of the keys because we may remove clients
	# inside the loop if they disconnect.
	var peers: Array = _clients.keys()
	for peer: StreamPeerTCP in peers:
		# Godot 4: poll() must be called each frame to drive the connection
		# state machine. Godot 3 does this internally.
		peer.poll()

		var status: StreamPeerTCP.Status = peer.get_status()

		if status == StreamPeerTCP.STATUS_NONE or status == StreamPeerTCP.STATUS_ERROR:
			# Client disconnected or errored out — remove it.
			_remove_client(peer)
			continue

		if status != StreamPeerTCP.STATUS_CONNECTED:
			# Still connecting — nothing to read yet.
			continue

		# Read available bytes (up to the per-tick cap).
		var available: int = peer.get_available_bytes()
		if available <= 0:
			continue

		var bytes_to_read: int = mini(available, MAX_READ_BYTES_PER_TICK)
		# Godot 4: get_data() returns [Error, PackedByteArray].
		# Godot 3: get_data() returns [Error, PoolByteArray].
		var result: Array = peer.get_data(bytes_to_read)
		var err: Error = result[0]
		if err != OK:
			push_warning("[MCP] Read error on client (Error %d), disconnecting." % err)
			_remove_client(peer)
			continue

		var data: PackedByteArray = result[1]
		var text: String = data.get_string_from_utf8()

		# Append to this client's buffer.
		var client_state: Dictionary = _clients[peer]
		client_state["buffer"] += text

		# Guard against oversized payloads (> 1 MB).
		if client_state["buffer"].length() > 1048576:
			send_response(peer, "error", {"message": "Request too large (buffer exceeded 1 MB limit)"})
			_remove_client(peer)
			continue

		# Process complete lines (newline-delimited JSON protocol).
		_process_buffer(peer, client_state)


# ---------------------------------------------------------------------------
# Buffer processing — extract complete JSON lines and dispatch
# ---------------------------------------------------------------------------

func _process_buffer(peer: StreamPeerTCP, client_state: Dictionary) -> void:
	# Split on newline. The last element may be an incomplete line — keep it.
	while true:
		var newline_pos: int = client_state["buffer"].find("\n")
		if newline_pos == -1:
			break

		var line: String = client_state["buffer"].substr(0, newline_pos).strip_edges()
		client_state["buffer"] = client_state["buffer"].substr(newline_pos + 1)

		if line.is_empty():
			continue

		# Try to parse the JSON command.
		var json := JSON.new()
		# Godot 4: JSON.parse() returns an Error; parsed data lives in .data.
		# Godot 3: JSON.parse() returns a JSONParseResult object.
		var parse_err: Error = json.parse(line)
		if parse_err != OK:
			push_warning("[MCP] Invalid JSON from client: %s" % json.get_error_message())
			send_response(peer, "error", {"message": "Invalid JSON: %s" % json.get_error_message()})
			continue

		var command: Variant = json.data
		if typeof(command) != TYPE_DICTIONARY:
			send_response(peer, "error", {"message": "Expected a JSON object, got %s" % type_string(typeof(command))})
			continue

		# Dispatch the command.
		_handle_command(peer, command as Dictionary)


# ---------------------------------------------------------------------------
# Command dispatcher
# ---------------------------------------------------------------------------

## Routes an incoming command dictionary to the appropriate handler based on
## the "type" field. This is the central dispatch table — new command modules
## (graph.gd, parameters.gd, etc.) will register their handlers here.
##
## Many MM APIs are async (use await), so this function is async and uses
## _dispatch_async() which awaits the handler result before sending a response.
func _handle_command(peer: StreamPeerTCP, command: Dictionary) -> void:
	if not command.has("type"):
		send_response(peer, "error", {"message": "Command missing required 'type' field."})
		return

	var cmd_type: String = command.get("type", "")
	var params: Dictionary = command.get("params", {})

	# ----- Scene / Project commands -----
	match cmd_type:
		"get_scene_info":
			_dispatch(peer, _scene_commands.get_scene_info(params))
		"save_project":
			_dispatch(peer, _scene_commands.save_project(params))
		"load_project":
			await _dispatch_async(peer, _scene_commands.load_project(params))
		"new_project":
			await _dispatch_async(peer, _scene_commands.new_project(params))

		# ----- Graph / Node commands -----
		"create_node":
			await _dispatch_async(peer, _graph_commands.create_node(params))
		"delete_node":
			_dispatch(peer, _graph_commands.delete_node(params))
		"connect_nodes":
			_dispatch(peer, _graph_commands.connect_nodes(params))
		"disconnect_nodes":
			_dispatch(peer, _graph_commands.disconnect_nodes(params))
		"get_graph_info":
			_dispatch(peer, _graph_commands.get_graph_info(params))
		"list_available_nodes":
			_dispatch(peer, _graph_commands.list_available_nodes(params))

		# ----- Parameter commands -----
		"get_node_parameters":
			_dispatch(peer, _parameter_commands.get_node_parameters(params))
		"set_node_parameter":
			_dispatch(peer, _parameter_commands.set_node_parameter(params))
		"set_multiple_parameters":
			_dispatch(peer, _parameter_commands.set_multiple_parameters(params))

		# ----- Export commands -----
		"export_material":
			await _dispatch_async(peer, _export_commands.export_material(params))
		"export_for_engine":
			await _dispatch_async(peer, _export_commands.export_for_engine(params))
		"list_export_profiles":
			_dispatch(peer, _export_commands.list_export_profiles(params))

		# ----- Utility / escape hatch -----
		"execute_mm_script":
			_dispatch(peer, _utils_commands.execute_mm_script(params))

		# ----- Ping / health check -----
		"ping":
			send_response(peer, "ok", {
				"pong": true,
				"protocol_version": PROTOCOL_VERSION,
				"port": _port,
			})

		# ----- Unknown command -----
		_:
			send_response(peer, "error", {
				"message": "Unknown command type: '%s'" % cmd_type,
				"available_commands": [
					"ping",
					"get_scene_info", "save_project", "load_project", "new_project",
					"create_node", "delete_node", "connect_nodes", "disconnect_nodes",
					"get_graph_info", "list_available_nodes",
					"get_node_parameters", "set_node_parameter", "set_multiple_parameters",
					"export_material", "export_for_engine", "list_export_profiles",
					"execute_mm_script",
				],
			})


# ---------------------------------------------------------------------------
# Dispatch helper — routes command handler results to send_response
# ---------------------------------------------------------------------------

## Takes the Dictionary returned by a command handler and sends the appropriate
## response. If the result contains an "error" key, it's sent as an error.
func _dispatch(peer: StreamPeerTCP, result: Dictionary) -> void:
	if result.has("error") and result["error"] == true:
		send_response(peer, "error", {"message": result.get("message", "Unknown error")})
	else:
		send_response(peer, "ok", result)


## Async version of _dispatch — awaits the handler result before sending.
## Used for MM APIs that require await (create_node, load_project, export, etc.).
func _dispatch_async(peer: StreamPeerTCP, result) -> void:
	var resolved: Dictionary = await result
	_dispatch(peer, resolved)


# ---------------------------------------------------------------------------
# Response helper
# ---------------------------------------------------------------------------

## Serialise a response dictionary and send it to the peer as a single
## newline-terminated JSON line. This is the only function that writes to the
## socket — all command handlers call this.
func send_response(peer: StreamPeerTCP, status: String, data: Dictionary) -> void:
	var response: Dictionary = {
		"status": status,
	}

	# Merge data into the response. For "ok" responses the payload goes under
	# "result"; for "error" responses the message is top-level.
	if status == "ok":
		response["result"] = data
	else:
		# Flatten error fields (typically just "message") into the response root.
		response.merge(data)

	var json_str: String = JSON.stringify(response)
	var payload: PackedByteArray = (json_str + "\n").to_utf8_buffer()

	# Godot 4: put_data() returns an Error.
	# Godot 3: put_data() also returns an Error.
	var err: Error = peer.put_data(payload)
	if err != OK:
		push_warning("[MCP] Failed to send response to client (Error %d)." % err)


# ---------------------------------------------------------------------------
# Client management helpers
# ---------------------------------------------------------------------------

## Remove a client from the tracking dictionary and disconnect it.
func _remove_client(peer: StreamPeerTCP) -> void:
	if _clients.has(peer):
		_clients.erase(peer)
	peer.disconnect_from_host()
	print("[MCP] Client disconnected (%d remaining)." % _clients.size())
