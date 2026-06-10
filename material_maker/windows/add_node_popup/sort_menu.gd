class_name SortMenu
extends PopupPanel

signal sorting_changed

enum Sorting {
	FREQUENCY_ASCENDING,
	FREQUENCY_DESCENDING,
	ALPHABETICAL_ASCENDING,
	ALPHABETICAL_DESCENDING,
	CATEGORY_ASCENDING,
	CATEGORY_DESCENDING,
	QUALITY_DESCENDING,
}

static func item_used(usage_map : Dictionary, item : String) -> int:
	if usage_map.has(item):
		return usage_map[item]
	return 0

static func sort_function(type : Sorting, freq_map : Dictionary) -> Callable:
	match type:
		Sorting.QUALITY_DESCENDING:
			return func(a : Dictionary, b : Dictionary) -> bool:
				return a.idx < b.idx if a.quality == b.quality else a.quality > b.quality
		Sorting.FREQUENCY_ASCENDING:
			return func(a : Dictionary, b : Dictionary) -> bool:
					var a_freq = item_used(freq_map, a.name)
					var b_freq = item_used(freq_map, b.name)
					return a_freq < b_freq if a_freq != b_freq else a.quality > b.quality
		Sorting.FREQUENCY_DESCENDING:
			return func(a : Dictionary, b : Dictionary) -> bool:
					var a_freq = item_used(freq_map, a.name)
					var b_freq = item_used(freq_map, b.name)
					return a_freq > b_freq if a_freq != b_freq else a.quality > b.quality
		Sorting.ALPHABETICAL_ASCENDING:
			return func(a : Dictionary, b : Dictionary) -> bool:
					return a.item.display_name.naturalcasecmp_to(b.item.display_name) == -1
		Sorting.ALPHABETICAL_DESCENDING:
			return func(a : Dictionary, b : Dictionary) -> bool:
					return a.item.display_name.naturalcasecmp_to(b.item.display_name) == 1
		Sorting.CATEGORY_ASCENDING:
			return func(a : Dictionary, b : Dictionary) -> bool:
					return a.name.naturalcasecmp_to(b.name) == -1
		Sorting.CATEGORY_DESCENDING:
			return func(a : Dictionary, b : Dictionary) -> bool:
					return a.name.naturalcasecmp_to(b.name) == 1
	return sort_function(Sorting.QUALITY_DESCENDING, freq_map)

func _ready() -> void:
	content_scale_factor = get_tree().root.content_scale_factor
	load_button_state()

func load_button_state() -> void:
	match get_parent().item_sort_mode:
		Sorting.FREQUENCY_ASCENDING:
			%Frequency.icon_name = "frequency_ascending"
			%Frequency.button_pressed = true
		Sorting.FREQUENCY_DESCENDING:
			%Frequency.icon_name = "frequency_descending"
			%Frequency.button_pressed = true
		Sorting.ALPHABETICAL_ASCENDING:
			%Alphabetical.icon_name = "alphabetical_ascending"
			%Alphabetical.button_pressed = true
		Sorting.ALPHABETICAL_DESCENDING:
			%Alphabetical.icon_name = "alphabetical_descending"
			%Alphabetical.button_pressed = true
		Sorting.CATEGORY_ASCENDING:
			%Category.icon_name = "category_ascending"
			%Category.button_pressed = true
		Sorting.CATEGORY_DESCENDING:
			%Category.icon_name = "category_descending"
			%Category.button_pressed = true
		Sorting.QUALITY_DESCENDING:
			%Quality.button_pressed = true

	# update button icons
	for btn in $PanelContainer/VBoxContainer.get_children():
		btn._ready()

func toggle_button_icon(btn : SimpleButton) -> void:
	if "ascending" in btn.icon_name:
		btn.icon_name = btn.name.to_lower() + "_descending"
	else:
		btn.icon_name = btn.name.to_lower() + "_ascending"
	btn._ready()

func save_button_state(btn : SimpleButton) -> void:
	var sort : Sorting
	var ascending : bool = "ascending" in btn.icon_name
	match btn.name.to_lower():
		"frequency":
			sort = Sorting.FREQUENCY_ASCENDING if ascending else Sorting.FREQUENCY_DESCENDING
		"alphabetical":
			sort = Sorting.ALPHABETICAL_ASCENDING if ascending else Sorting.ALPHABETICAL_DESCENDING
		"category":
			sort = Sorting.CATEGORY_ASCENDING if ascending else Sorting.CATEGORY_DESCENDING
		"quality":
			sort = Sorting.QUALITY_DESCENDING
	mm_globals.set_config("add_node_popup_sort", sort)
	get_parent().item_sort_mode = sort

func _on_frequency_pressed() -> void:
	toggle_button_icon(%Frequency)
	save_button_state(%Frequency)
	sorting_changed.emit()

func _on_alphabetical_pressed() -> void:
	toggle_button_icon(%Alphabetical)
	save_button_state(%Alphabetical)
	sorting_changed.emit()

func _on_category_pressed() -> void:
	toggle_button_icon(%Category)
	save_button_state(%Category)
	sorting_changed.emit()

func _on_quality_pressed() -> void:
	save_button_state(%Quality)
	sorting_changed.emit()
