extends GutTest

var doc_dir: String = "res://material_maker/doc"
var library_json_path: String = "res://material_maker/library/base.json"

var simple_nodes: Array[String]
var sdf3d_nodes: Array[String]
var pattern_nodes: Array[String]
var noise_nodes: Array[String]
var filter_nodes: Array[String]
var transform_nodes: Array[String]
var workflow_nodes: Array[String]
var miscellaneous_nodes: Array[String]

func before_all() -> void:
	var file := FileAccess.open(library_json_path, FileAccess.READ)
	var lib_data = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(lib_data)
	if error == OK:
		var data_received = json.data
		if typeof(data_received.lib) == TYPE_ARRAY:
			for a in data_received.lib:
				var node: String = a.tree_item
				node = node.to_lower().replace("/", "_").replace(" ", "_")
				if node.begins_with("simple"):
					simple_nodes.append(node)
					continue
				if node.begins_with("3d"):
					sdf3d_nodes.append(node)
					continue
				if node.begins_with("pattern"):
					pattern_nodes.append(node)
					continue
				if node.begins_with("noise"):
					noise_nodes.append(node)
					continue
				if node.begins_with("filter"):
					filter_nodes.append(node)
					continue
				if node.begins_with("transform"):
					transform_nodes.append(node)
					continue
				if node.begins_with("workflow"):
					workflow_nodes.append(node)
					continue
				if node.begins_with("miscellaneous"):
					miscellaneous_nodes.append(node)
					continue

	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", lib_data, " at line ", json.get_error_line())
	print("done")

func test_simple_nodes_documentation_completion() -> void:
	var ratio: float = check_node_array_for_completion(simple_nodes)
	assert_eq(ratio, 1.0, "SIMPLE NODES DOCUMENTATION: %d%%" % [ratio*100])

func test_3d_nodes_documentation_completion() -> void:
	var ratio: float = check_node_array_for_completion(sdf3d_nodes)
	assert_eq(ratio, 1.0, "3D NODES DOCUMENTATION: %d%%" % [ratio*100])

func test_pattern_nodes_documentation_completion() -> void:
	var ratio: float = check_node_array_for_completion(pattern_nodes)
	assert_eq(ratio, 1.0, "PATTERN NODES DOCUMENTATION: %d%%" % [ratio*100])

func test_noise_nodes_documentation_completion() -> void:
	var ratio: float = check_node_array_for_completion(noise_nodes)
	assert_eq(ratio, 1.0, "NOISE NODES DOCUMENTATION: %d%%" % [ratio*100])

func test_filter_nodes_documentation_completion() -> void:
	var ratio: float = check_node_array_for_completion(filter_nodes)
	assert_eq(ratio, 1.0, "FILTER NODES DOCUMENTATION: %d%%" % [ratio*100])

func test_transform_nodes_documentation_completion() -> void:
	var ratio: float = check_node_array_for_completion(transform_nodes)
	assert_eq(ratio, 1.0, "TRANSFORM NODES DOCUMENTATION: %d%%" % [ratio*100])

func test_workflow_nodes_documentation_completion() -> void:
	var ratio: float = check_node_array_for_completion(workflow_nodes)
	assert_eq(ratio, 1.0, "WORKFLOW NODES DOCUMENTATION: %d%%" % [ratio*100])

func test_miscellaneous_nodes_documentation_completion() -> void:
	var ratio: float = check_node_array_for_completion(miscellaneous_nodes)
	assert_eq(ratio, 1.0, "MISCELLANEOUS NODES DOCUMENTATION: %d%%" % [ratio*100])

func check_node_array_for_completion(node_list: Array) -> float:
	var failed_tests: int = 0
	for node in node_list:
		var found_node_doc: String = node
		while true:
			var doc_path : String = doc_dir + "/node_" + found_node_doc + ".rst"
			if FileAccess.file_exists(doc_path):
				assert_true(true, "Found docs for node \"%s\" at file \"%s\"" % [node,doc_path])
				break

			else:
				var next_underscore = found_node_doc.rfind("_")
				if next_underscore == -1:
					assert_true(false, "Could not find documentation for node \"%s\"" % node)
					failed_tests += 1
					break
				else:
					found_node_doc = found_node_doc.left(next_underscore)
	return ((float(node_list.size()) - float(failed_tests)) / float(node_list.size()))
