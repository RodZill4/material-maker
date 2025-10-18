class_name MMMeshLoader

static func get_file_dialog_filters() -> Array[String]:
	return [ "*.glb,*.gltf;GLTF file", "*.obj;Wavefront OBJ file", "*.fbx;FBX file" ]

static func load_gltf_mesh(file_path) -> ArrayMesh:
	# Contributed by wojtekpil
	# This will load gltf mesh and return #1 Mesh of #1 MeshInstance
	# Material Editing will work only on first surface too. This should be easy to
	# fix with MeshInstance.material_overwrite instaed of get_surface_override_material
	# Probably can be improved later to combine/support all Meshes in GTLF
	var gltf : GLTFDocument = GLTFDocument.new()
	var gltf_state : GLTFState = GLTFState.new()
	if not FileAccess.file_exists(file_path):
		printerr("GLTF/GLB file does not exists or is not accesible")
		return null
	var glb_filebytes = FileAccess.get_file_as_bytes(file_path)
	if glb_filebytes == null:
		printerr("GLTF/GLB file data is null")
		return null
	var err = gltf.append_from_buffer(glb_filebytes, "", gltf_state)
	if err != OK:
		printerr("Failure during parsing GLTF/GLB buffer")
		return null
	var node: Node = gltf.generate_scene(gltf_state)
	if node is MeshInstance3D:
		return node.mesh
	var mesh_instances : Array[Node] = node.find_children("*", "MeshInstance3D", true, false)
	if mesh_instances.size() == 0:
		printerr("GLTF/GLB does not include any meshes")
		return null
	return mesh_instances[0].mesh

static func load_fbx_mesh(file_path) -> ArrayMesh:
	var fbx : FBXDocument = FBXDocument.new()
	var fbx_state : FBXState = FBXState.new()
	if not FileAccess.file_exists(file_path):
		push_error("FBX file does not exists or is not accessible")
		return null
	var fbx_filebytes = FileAccess.get_file_as_bytes(file_path)
	if fbx_filebytes == null:
		push_error("FBX file data is null")
		return null
	var err = fbx.append_from_buffer(fbx_filebytes, "", fbx_state)
	if err != OK:
		push_error("Failure during parsing FBX buffer")
		return null
	var node: Node = fbx.generate_scene(fbx_state)
	if node is MeshInstance3D:
		return node.mesh
	var mesh_instances : Array[Node] = node.find_children("*", "MeshInstance3D", true, false)
	if mesh_instances.size() == 0:
		push_error("FBX does not include any meshes")
		return null
	return mesh_instances[0].mesh

static func load_mesh(path : String) -> ArrayMesh:
	if path == null:
		return null
	var ext : String = path.get_extension()
	var mesh : ArrayMesh = null
	if ext.matchn("obj"):
		var obj_loader = load("res://addons/material_maker/loaders/obj_loader.gd")
		mesh = obj_loader.load_obj_file(path)
	elif ext.matchn("glb") or ext.matchn("gltf"):
		mesh = load_gltf_mesh(path)
	elif ext.matchn("fbx"):
		mesh = load_fbx_mesh(path)
	if mesh:
		mesh.set_meta("file_path", path)
	return mesh
