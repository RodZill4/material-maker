extends VBoxContainer

var recents : Array = []
var favorites : Array = []

signal open_directory(dirpath)

func _ready():
	if get_node("/root/MainWindow") != null:
		var config_cache = get_node("/root/MainWindow").config_cache
		if config_cache.has_section_key("file_dialog", "recents"):
			var parse_result = JSON.parse(config_cache.get_value("file_dialog", "recents"))
			if parse_result != null:
				recents = parse_result.result
		if config_cache.has_section_key("file_dialog", "favorites"):
			var parse_result = JSON.parse(config_cache.get_value("file_dialog", "favorites"))
			if parse_result != null:
				favorites = parse_result.result
		update_lists()

func _exit_tree():
	if get_node("/root/MainWindow") != null:
		var config_cache = get_node("/root/MainWindow").config_cache
		config_cache.set_value("file_dialog", "recents", JSON.print(recents))
		config_cache.set_value("file_dialog", "favorites", JSON.print(favorites))

func add_recent(file_path : String):
	if recents.find(file_path) != -1:
		recents.erase(file_path)
	recents.push_front(file_path)
	update_lists()

func add_favorite(file_path : String):
	if favorites.find(file_path) == -1:
		favorites.push_back(file_path)
		update_lists()

func my_basename(s : String) -> String:
	var slash_pos : int = s.find_last("/")
	if slash_pos == -1 or slash_pos+1 == s.length():
		return s
	return s.right(slash_pos+1)

func update_lists():
	$FavList.clear()
	for d in favorites:
		$FavList.add_item(my_basename(d))
		$FavList.set_item_tooltip($FavList.get_item_count()-1, d)
	$RecentList.clear()
	for d in recents:
		$RecentList.add_item(my_basename(d))
		$RecentList.set_item_tooltip($RecentList.get_item_count()-1, d)

func _on_FavList_item_activated(index):
	emit_signal("open_directory", $FavList.get_item_tooltip(index))

func _on_RecentList_item_activated(index):
	emit_signal("open_directory", $RecentList.get_item_tooltip(index))

func _on_FavList_gui_input(event):
	if event is InputEventKey and event.pressed and event.scancode == KEY_DELETE:
		if ! $FavList.get_selected_items().empty():
			favorites.remove($FavList.get_selected_items()[0])
			update_lists()

func _on_RecentList_gui_input(event):
	if event is InputEventKey and event.pressed and event.scancode == KEY_DELETE:
		if ! $RecentList.get_selected_items().empty():
			recents.remove($RecentList.get_selected_items()[0])
			update_lists()
