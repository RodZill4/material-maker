@tool
extends Tree

var _show_orphans = true
var show_orphans = true :
	get: return _show_orphans
	set(val): _show_orphans = val


var _hide_passing = true
var hide_passing = true :
	get: return _hide_passing
	set(val): _hide_passing = val


var _icons = {
	red = load('res://addons/gut/images/red.png'),
	green = load('res://addons/gut/images/green.png'),
	yellow = load('res://addons/gut/images/yellow.png'),
}

@export var script_entry_color : Color = Color(0, 0, 0, .2) :
	set(val):
		if(val != null):
			script_entry_color = val
@export var column_0_color : Color = Color(1, 1, 1, 0) :
	set(val):
		if(val != null):
			column_0_color = val
@export var column_1_color : Color = Color(0, 0, 0, .2):
	set(val):
		if(val != null):
			column_1_color = val



var _max_icon_width = 10
var _root : TreeItem


@onready var lbl_overlay = $TextOverlay


signal selected(script_path, inner_class, test_name, line_number)

func _debug_ready():
	hide_passing = false
	load_json_file('user://gut_temp_directory/gut_editor.json')


func _ready():
	_root = create_item()
	set_hide_root(true)
	columns = 2
	set_column_expand(0, true)
	set_column_expand_ratio(0, 5)

	set_column_expand_ratio(1, 1)
	set_column_expand(1, true)

	item_selected.connect(_on_tree_item_selected)

	if(get_parent() == get_tree().root):
		_debug_ready()


# -------------------
# Private
# -------------------
func _get_line_number_from_assert_msg(msg):
	var line = -1
	if(msg.find('at line') > 0):
		line = msg.split("at line")[-1].split(" ")[-1].to_int()
	return line


func _get_path_and_inner_class_name_from_test_path(path):
	var to_return = {
		path = '',
		inner_class = ''
	}

	to_return.path = path
	if !path.ends_with('.gd'):
		var loc = path.find('.gd')
		to_return.inner_class = path.split('.')[-1]
		to_return.path = path.substr(0, loc + 3)
	return to_return


func _find_script_item_with_path(path):
	var items = _root.get_children()
	var to_return = null

	var idx = 0
	while(idx < items.size() and to_return == null):
		var item = items[idx]
		if(item.get_metadata(0).path == path):
			to_return = item
		else:
			idx += 1

	return to_return


func _add_script_tree_item(script_path, script_json):
	var path_info = _get_path_and_inner_class_name_from_test_path(script_path)
	var item_text = script_path
	var parent = _root

	if(path_info.inner_class != ''):
		parent = _find_script_item_with_path(path_info.path)
		item_text = path_info.inner_class
		if(parent == null):
			parent = _add_script_tree_item(path_info.path, {})

	var item = create_item(parent)
	item.set_text(0, item_text)
	var meta = {
		"type":"script",
		"path":path_info.path,
		"inner_class":path_info.inner_class,
		"json":script_json,
		"inner_passing":0,
		"inner_tests":0
	}
	item.set_metadata(0, meta)
	item.set_custom_bg_color(0, script_entry_color)
	item.set_custom_bg_color(1, script_entry_color)

	return item


func _add_assert_item(text, icon, parent_item):
	# print('        * adding assert')
	var assert_item = create_item(parent_item)
	assert_item.set_icon_max_width(0, _max_icon_width)
	assert_item.set_text(0, text)
	assert_item.set_metadata(0, {"type":"assert"})
	assert_item.set_icon(0, icon)
	assert_item.set_custom_bg_color(0, column_0_color)
	assert_item.set_custom_bg_color(1, column_1_color)

	return assert_item


func _add_test_tree_item(test_name, test_json, script_item):
	# print('    * adding test ', test_name)
	var no_orphans_to_show = !_show_orphans or (_show_orphans and test_json.orphan_count == 0)
	if(_hide_passing and test_json['status'] == 'pass' and no_orphans_to_show):
		return

	var item = create_item(script_item)
	var status = test_json['status']
	var meta = {"type":"test", "json":test_json}

	item.set_text(0, test_name)
	item.set_text(1, status)
	item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
	item.set_custom_bg_color(1, column_1_color)

	item.set_metadata(0, meta)
	item.set_icon_max_width(0, _max_icon_width)
	item.set_custom_bg_color(0, column_0_color)

	if(status == 'pass' and no_orphans_to_show):
		item.set_icon(0, _icons.green)
	elif(status == 'fail'):
		item.set_icon(0, _icons.red)
	else:
		item.set_icon(0, _icons.yellow)

	if(!_hide_passing):
		for passing in test_json.passing:
			_add_assert_item('pass: ' + passing, _icons.green, item)

	for failure in test_json.failing:
		_add_assert_item("fail:  " + failure.replace("\n", ''), _icons.red, item)

	for pending in test_json.pending:
		_add_assert_item("pending:  " + pending.replace("\n", ''), _icons.yellow, item)

	var orphan_text = 'orphans'
	if(test_json.orphan_count == 1):
		orphan_text = 'orphan'
	orphan_text = str(int(test_json.orphan_count), ' ', orphan_text)

	if(!no_orphans_to_show):
		var orphan_item = _add_assert_item(orphan_text, _icons.yellow, item)
		for o in test_json.orphans:
			var orphan_entry = create_item(orphan_item)
			orphan_entry.set_text(0, o)
			orphan_entry.set_custom_bg_color(0, column_0_color)
			orphan_entry.set_custom_bg_color(1, column_1_color)

	return item


func _add_script_to_tree(key, script_json):
	var tests = script_json['tests']
	var test_keys = tests.keys()
	var s_item = _add_script_tree_item(key, script_json)
	var bad_count = 0

	for test_key in test_keys:
		var t_item = _add_test_tree_item(test_key, tests[test_key], s_item)
		if(tests[test_key].status != 'pass'):
			bad_count += 1
		elif(t_item != null):
			t_item.collapsed = true

	if(s_item.get_children().size() == 0):
		if(script_json.props.skipped):
			_add_assert_item("Skipped", _icons.yellow, s_item)
			s_item.set_text(1, "Skipped")
		else:
			s_item.free()
	else:
		var total_text = str('All ', test_keys.size(), ' passed')
		if(bad_count == 0):
			s_item.collapsed = true
		else:
			total_text = str(int(test_keys.size() - bad_count), '/', int(test_keys.size()), ' passed')
		s_item.set_text(1, total_text)


func _free_childless_scripts():
	var items = _root.get_children()
	for item in items:
		var next_item = item.get_next()
		if(item.get_children().size() == 0):
			item.free()
		item = next_item


func _show_all_passed():
	if(_root.get_children().size() == 0):
		add_centered_text('Everything passed!')


func _load_result_tree(j):
	var scripts = j['test_scripts']['scripts']
	var script_keys = scripts.keys()
	# if we made it here, the json is valid and we did something, otherwise the
	# 'nothing to see here' should be visible.
	clear_centered_text()

	var add_count = 0
	for key in script_keys:
		add_count += 1
		_add_script_to_tree(key, scripts[key])

	_free_childless_scripts()
	if(add_count == 0):
		add_centered_text('Nothing was run')
	else:
		_show_all_passed()
# -------------------
# Events
# -------------------
func _on_tree_item_selected():
	var item = get_selected()
	var item_meta = item.get_metadata(0)
	var item_type = null

	# Only select the left side of the tree item, cause I like that better.
	# you can still click the right, but only the left gets highlighted.
	if(item.is_selected(1)):
		item.deselect(1)
		item.select(0)

	if(item_meta == null):
		return
	else:
		item_type = item_meta.type

	var script_path = '';
	var line = -1;
	var test_name = ''
	var inner_class = ''

	if(item_type == 'test'):
		var s_item = item.get_parent()
		script_path = s_item.get_metadata(0)['path']
		inner_class = s_item.get_metadata(0)['inner_class']
		line = -1
		test_name = item.get_text(0)
	elif(item_type == 'assert'):
		var s_item = item.get_parent().get_parent()
		script_path = s_item.get_metadata(0)['path']
		inner_class = s_item.get_metadata(0)['inner_class']
		line = _get_line_number_from_assert_msg(item.get_text(0))
		test_name = item.get_parent().get_text(0)
	elif(item_type == 'script'):
		script_path = item.get_metadata(0)['path']
		if(item.get_parent() != _root):
			inner_class = item.get_text(0)
		line = -1
		test_name = ''
	else:
		return

	selected.emit(script_path, inner_class, test_name, line)


# -------------------
# Public
# -------------------
func load_json_file(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var text = ''
	if(file != null):
		text = file.get_as_text()

	if(text != ''):
		var test_json_conv = JSON.new()
		var result = test_json_conv.parse(text)
		if(result != OK):
			add_centered_text(str(path, " has invalid json in it \n",
				'Error ', result, "@", test_json_conv.get_error_line(), "\n",
				test_json_conv.get_error_message()))
			return

		var data = test_json_conv.get_data()
		load_json_results(data)
	else:
		add_centered_text(str(path, ' was empty or does not exist.'))


func load_json_results(j):
	clear()
	if(_root == null):
		_root = create_item()

	_load_result_tree(j)


#func clear():
	#clear()
	#_root = create_item()


func set_summary_min_width(width):
	set_column_custom_minimum_width(1, width)


func add_centered_text(t):
	lbl_overlay.visible = true
	lbl_overlay.text = t


func clear_centered_text():
	lbl_overlay.visible = false
	lbl_overlay.text = ''


func collapse_all():
	set_collapsed_on_all(_root, true)


func expand_all():
	set_collapsed_on_all(_root, false)


func set_collapsed_on_all(item, value):
	item.set_collapsed_recursive(value)
	if(item == _root and value):
		item.set_collapsed(false)
