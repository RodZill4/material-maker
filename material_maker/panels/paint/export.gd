extends Node


const CHANNELS = [ "albedo", "metallic", "roughness", "emission", "normal", "occlusion", "depth" ]


func _ready():
	var graph = MMGenGraph.new()
	graph.name = "graph"
	add_child(graph)
	var material = await mm_loader.create_gen({ name="material", type="material" })
	graph.add_child(material)
	for i in CHANNELS.size():
		if CHANNELS[i] == null:
			continue
		var node = MMGenTexture.new()
		node.name = CHANNELS[i]
		graph.add_child(node)
		graph.connect_children(node, 0, material, i)

func setup_material(material_textures : Dictionary) -> void:
	var graph = get_node("graph")
	for c in CHANNELS:
		if c == null:
			continue
		var channel_node = graph.get_node(c)
		channel_node.texture.set_image(material_textures[c].get_image())
		mm_deps.dependency_update("o%d_tex" % channel_node.get_instance_id(), channel_node.texture)
	graph.get_node("material").all_sources_changed()


func get_material_node() -> Node:
	return get_node("graph/material")
