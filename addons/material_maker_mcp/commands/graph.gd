## graph.gd -- Graph and node command handlers for Material Maker MCP
##
## Handles: create_node, delete_node, connect_nodes, disconnect_nodes,
##          get_graph_info, list_available_nodes
##
## Uses real Material Maker APIs:
##   - _main_window.get_current_graph_edit() -> MMGraphEdit
##   - graph_edit.generator -> MMGenGraph (current sub-graph)
##   - graph_edit.top_generator -> MMGenGraph (root graph)
##   - graph.get_children() -> Array of MMGenBase nodes
##   - graph.connections -> Array of {from, from_port, to, to_port}

extends RefCounted

var _main_window = null


func init(main_window) -> void:
	_main_window = main_window


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Return the currently active MMGraphEdit from the main window.
func _get_graph_edit():
	if _main_window == null:
		return null
	return _main_window.get_current_graph_edit()


## Return the current MMGenGraph (the generator graph being viewed).
func _get_graph():
	var graph_edit = _get_graph_edit()
	if graph_edit == null:
		return null
	return graph_edit.generator


## Build a standardised error dictionary.
func _error(message: String) -> Dictionary:
	return {"error": true, "message": message}


# ---------------------------------------------------------------------------
# Command: create_node
# ---------------------------------------------------------------------------

## Create a new node in the current material graph.
##
## Params:
##   node_type  : String  -- e.g. "noise_perlin", "bricks", "normal_map"
##   position_x : float   -- X position in graph space (default 0)
##   position_y : float   -- Y position in graph space (default 0)
##
## Returns: { node_id, node_type, position: { x, y } }
func create_node(params: Dictionary):
	var node_type: String = params.get("node_type", "")
	if node_type.is_empty():
		return _error("Missing required parameter: node_type")

	var graph_edit = _get_graph_edit()
	if graph_edit == null:
		return _error("No active graph. Is a project open in Material Maker?")

	var pos_x: float = float(params.get("position_x", 0.0))
	var pos_y: float = float(params.get("position_y", 0.0))
	var position := Vector2(pos_x, pos_y)

	# create_nodes is async -- returns an array of created UI nodes.
	var node_data := {"type": node_type, "parameters": {}}
	var created_nodes = await graph_edit.create_nodes(node_data, position)

	if created_nodes == null or created_nodes.is_empty():
		return _error("Failed to create node of type '%s'. Is the type name valid?" % node_type)

	var ui_node = created_nodes[0]
	var generator = ui_node.generator
	var node_id: String = generator.name
	var final_pos: Vector2 = generator.position

	return {
		"node_id": node_id,
		"node_type": node_type,
		"position": {"x": final_pos.x, "y": final_pos.y},
	}


# ---------------------------------------------------------------------------
# Command: delete_node
# ---------------------------------------------------------------------------

## Delete a node from the current graph by its ID (generator name).
##
## Params:
##   node_id : String -- the generator's name in the graph
##
## Returns: { deleted: true, node_id }
func delete_node(params: Dictionary) -> Dictionary:
	var node_id: String = params.get("node_id", "")
	if node_id.is_empty():
		return _error("Missing required parameter: node_id")

	var graph = _get_graph()
	if graph == null:
		return _error("No active graph. Is a project open in Material Maker?")

	var generator = graph.get_node(NodePath(node_id))
	if generator == null:
		return _error("Node '%s' not found in the current graph." % node_id)

	if generator.has_method("can_be_deleted") and not generator.can_be_deleted():
		return _error("Node '%s' cannot be deleted (e.g. the Material output node)." % node_id)

	var removed: bool = graph.remove_generator(generator)
	if not removed:
		return _error("Failed to remove node '%s' from the graph." % node_id)

	return {"deleted": true, "node_id": node_id}


# ---------------------------------------------------------------------------
# Command: connect_nodes
# ---------------------------------------------------------------------------

## Connect an output port of one node to an input port of another.
##
## Params:
##   from_node_id : String -- source generator name
##   from_port    : int    -- output port index
##   to_node_id   : String -- destination generator name
##   to_port      : int    -- input port index
##
## Returns: { connected: true, from: { node_id, port }, to: { node_id, port } }
func connect_nodes(params: Dictionary) -> Dictionary:
	var from_node_id: String = params.get("from_node_id", "")
	var to_node_id: String = params.get("to_node_id", "")
	if from_node_id.is_empty() or to_node_id.is_empty():
		return _error("Missing required parameters: from_node_id and to_node_id")

	var from_port: int = int(params.get("from_port", 0))
	var to_port: int = int(params.get("to_port", 0))

	var graph = _get_graph()
	var graph_edit = _get_graph_edit()
	if graph == null or graph_edit == null:
		return _error("No active graph. Is a project open in Material Maker?")

	var from_gen = graph.get_node(NodePath(from_node_id))
	if from_gen == null:
		return _error("Source node '%s' not found." % from_node_id)

	var to_gen = graph.get_node(NodePath(to_node_id))
	if to_gen == null:
		return _error("Destination node '%s' not found." % to_node_id)

	# Connect at the data model level (triggers shader recompilation).
	var ok: bool = graph.connect_children(from_gen, from_port, to_gen, to_port)
	if not ok:
		return _error(
			"Failed to connect %s:%d -> %s:%d. Check port indices."
			% [from_node_id, from_port, to_node_id, to_port]
		)

	# Sync the UI layer. UI node names are prefixed with "node_".
	graph_edit.connect_node(
		"node_" + from_node_id, from_port,
		"node_" + to_node_id, to_port
	)

	return {
		"connected": true,
		"from": {"node_id": from_node_id, "port": from_port},
		"to": {"node_id": to_node_id, "port": to_port},
	}


# ---------------------------------------------------------------------------
# Command: disconnect_nodes
# ---------------------------------------------------------------------------

## Remove a connection between two nodes.
##
## Params:
##   from_node_id : String -- source generator name
##   from_port    : int    -- output port index
##   to_node_id   : String -- destination generator name
##   to_port      : int    -- input port index
##
## Returns: { disconnected: true, from_node_id, from_port, to_node_id, to_port }
func disconnect_nodes(params: Dictionary) -> Dictionary:
	var from_node_id: String = params.get("from_node_id", "")
	var to_node_id: String = params.get("to_node_id", "")
	if from_node_id.is_empty() or to_node_id.is_empty():
		return _error("Missing required parameters: from_node_id and to_node_id")

	var from_port: int = int(params.get("from_port", 0))
	var to_port: int = int(params.get("to_port", 0))

	var graph = _get_graph()
	var graph_edit = _get_graph_edit()
	if graph == null or graph_edit == null:
		return _error("No active graph. Is a project open in Material Maker?")

	var from_gen = graph.get_node(NodePath(from_node_id))
	if from_gen == null:
		return _error("Source node '%s' not found." % from_node_id)

	var to_gen = graph.get_node(NodePath(to_node_id))
	if to_gen == null:
		return _error("Destination node '%s' not found." % to_node_id)

	# Disconnect at the data model level.
	var ok: bool = graph.disconnect_children(from_gen, from_port, to_gen, to_port)
	if not ok:
		return _error(
			"Failed to disconnect %s:%d -> %s:%d. Connection may not exist."
			% [from_node_id, from_port, to_node_id, to_port]
		)

	# Sync the UI layer.
	graph_edit.disconnect_node(
		"node_" + from_node_id, from_port,
		"node_" + to_node_id, to_port
	)

	return {
		"disconnected": true,
		"from_node_id": from_node_id,
		"from_port": from_port,
		"to_node_id": to_node_id,
		"to_port": to_port,
	}


# ---------------------------------------------------------------------------
# Command: get_graph_info
# ---------------------------------------------------------------------------

## Serialize the entire current graph: all nodes with types, positions,
## parameters, and all connections between them.
##
## Params: (none)
##
## Returns: { nodes: [...], connections: [...] }
func get_graph_info(params: Dictionary) -> Dictionary:
	var graph = _get_graph()
	if graph == null:
		return _error("No active graph. Is a project open in Material Maker?")

	# Collect nodes from graph children (each child is an MMGenBase).
	var nodes_array: Array = []
	for child in graph.get_children():
		if not child.has_method("get_type"):
			continue

		var node_info: Dictionary = {
			"node_id": str(child.name),
			"node_type": child.get_type(),
			"position": {"x": child.position.x, "y": child.position.y},
			"parameters": child.parameters.duplicate() if child.parameters else {},
		}
		nodes_array.append(node_info)

	# Connections are stored as an Array of {from, from_port, to, to_port} dicts.
	var connections_array: Array = []
	for conn in graph.connections:
		connections_array.append({
			"from_node": str(conn["from"]),
			"from_port": int(conn["from_port"]),
			"to_node": str(conn["to"]),
			"to_port": int(conn["to_port"]),
		})

	return {
		"nodes": nodes_array,
		"connections": connections_array,
	}


# ---------------------------------------------------------------------------
# Command: list_available_nodes
# ---------------------------------------------------------------------------

## Return available node types from Material Maker's node library.
##
## Params:
##   category : String (optional) -- filter to a specific category
##
## Returns: { node_types: [...] } or { categories: {...} }
func list_available_nodes(params: Dictionary) -> Dictionary:
	var category_filter: String = params.get("category", "")

	# Try the flat sorted list from mm_loader first.
	var mm_loader = _main_window.get_node_or_null("/root/mm_loader")
	if mm_loader != null and mm_loader.has_method("get_generator_list"):
		var generator_list: Array = mm_loader.get_generator_list()
		if not category_filter.is_empty():
			# Filter by category prefix (e.g. "noise" matches "noise_perlin").
			var filtered: Array = []
			for gen_type in generator_list:
				if str(gen_type).begins_with(category_filter):
					filtered.append(str(gen_type))
			return {"node_types": filtered}
		return {"node_types": generator_list}

	# Fallback: use NodeLibraryManager for categorized results.
	var node_library_manager = _main_window.get_node_or_null("NodeLibraryManager")
	if node_library_manager == null:
		return _error("Cannot access node library. Neither mm_loader nor NodeLibraryManager found.")

	var categories: Dictionary = {}
	var items: Array = node_library_manager.get_items(category_filter)
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var name: String = item.get("name", "")
		var tree_item = item.get("item", {})
		var category: String = "uncategorized"
		if typeof(tree_item) == TYPE_DICTIONARY and tree_item.has("tree_item"):
			var tree_path: String = str(tree_item["tree_item"])
			var slash_pos: int = tree_path.rfind("/")
			if slash_pos >= 0:
				category = tree_path.substr(0, slash_pos)
		if not categories.has(category):
			categories[category] = []
		categories[category].append(name)

	return {"categories": categories}
