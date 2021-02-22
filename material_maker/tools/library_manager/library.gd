extends Object

var library_path : String = ""
var library_name : String = ""
var library_items : Array = []
var library_items_by_name : Dictionary = {}
var library_icons : Dictionary = {}
var read_only : bool = false

func _ready():
	pass

func load_library(path : String, ro : bool = false) -> bool:
	var file : File = File.new()
	path = path.replace("root://", OS.get_executable_path().get_base_dir()+"/")
	if file.open(path, File.READ) == OK:
		var data = parse_json(file.get_as_text())
		library_path = path
		library_name = data.name if data.has("name") else ""
		library_items = data.lib
		read_only = ro
		for i in data.lib:
			library_items_by_name[i.tree_item] = i
			var texture : ImageTexture = ImageTexture.new()
			var image : Image = Image.new()
			if i.has("icon_data"):
				image.load_png_from_buffer(Marshalls.base64_to_raw(i.icon_data))
			elif i.has("icon"):
				image.load(path.get_basename()+"/"+i.icon+".png")
				i.icon_data = Marshalls.raw_to_base64(image.save_png_to_buffer())
			else:
				library_icons[i.tree_item] = null
				continue
			texture.create_from_image(image)
			library_icons[i.tree_item] = texture
		return true
	return false

func get_items(filter : String, disabled_sections : Array) -> Array:
	var array : Array = []
	for i in library_items:
		if filter == "" or i.tree_item.to_lower().find(filter) != -1:
			var slash_pos = i.tree_item.find("/")
			var section_name = i.tree_item.left(slash_pos) if slash_pos != -1 else i.tree_item
			if disabled_sections.find(section_name) == -1:
				array.push_back({ name=i.tree_item, item=i, icon=library_icons[i.tree_item] })
	return array

func get_sections() -> Array:
	var sections : Array = Array()
	for i in library_items:
		var section_name = i.tree_item.left(i.tree_item.find("/"))
		if sections.find(section_name) == -1:
			sections.push_back(section_name)
	return Array(sections)

func get_full_item_name(item_name : String) -> String:
	return item_name.to_lower().replace("/", "_").replace(" ", "_")

func add_item(item_name : String, image : Image, data : Dictionary) -> void:
	if read_only:
		return
	data.tree_item = item_name
	data.icon_data = Marshalls.raw_to_base64(image.save_png_to_buffer())
	var new_library_items = []
	var inserted = false
	for i in library_items:
		if i.tree_item != item_name:
			new_library_items.push_back(i)
		elif !inserted:
			new_library_items.push_back(data)
			inserted = true
	if !inserted:
		new_library_items.push_back(data)
	library_items = new_library_items
	library_items_by_name[item_name] = data
	var texture : ImageTexture = ImageTexture.new()
	texture.create_from_image(image)
	library_icons[item_name] = texture
	var file = File.new()
	if file.open(library_path, File.WRITE) == OK:
		file.store_string(JSON.print({name=library_name, lib=library_items}, "\t", true))
		file.close()
