extends CodeEdit


const KEYWORDS : Array[String]  = [ "attribute", "uniform", "varying", "const", "in", "out",
									"inout", "discard", "return", "break", "continue", "do",
									"for", "while", "if", "else", "switch", "case", "default",
									"true", "false", "highp", "mediump", "lowp", "precision",
									"struct" ]

const TYPES : Array[String] = [ "void", "bool", "int", "uint", "float", "double", "bvec2",
								"bvec3", "bvec4", "ivec2", "ivec3", "ivec4", "uvec2",
								"uvec3", "uvec4", "vec2", "vec3", "vec4", "dvec2",
								"dvec3", "dvec4", "mat2", "mat3", "mat4", "mat2x2",
								"mat2x3", "mat2x4", "mat3x2", "mat3x3", "mat3x4",
								"mat4x2", "mat4x3", "mat4x4", "sampler1D", "sampler2D",
								"sampler3D", "samplerCube" ]

const FUNCTIONS : Array[String] = [ "radians", "degrees", "sin", "cos", "tan", "asin",
									"acos", "atan", "pow", "exp", "log", "exp2", "log2",
									"sqrt", "inversesqrt", "abs", "sign", "floor", "ceil",
									"fract", "mod", "min", "max", "clamp", "mix", "step",
									"smoothstep", "length", "distance", "dot", "cross",
									"normalize" ]


func _ready():
	add_comment_delimiter("//", "", true)
	add_comment_delimiter("/*", "*/", false)
	for t in KEYWORDS:
		syntax_highlighter.add_keyword_color(t, Color(1.0, 0.6, 0.6))
	for t in TYPES:
		syntax_highlighter.add_keyword_color(t, Color(1.0, 1.0, 0.5))
	for t in FUNCTIONS:
		syntax_highlighter.add_keyword_color(t, Color(0.5, 0.5, 1.0))

func _on_gui_input(event):
	if event is InputEventKey:
		if event.as_text_keycode() == "Ctrl+F":
			accept_event()
			%Find.visible = true
			%ReplaceControls.visible = false
			if get_selected_text() != "":
				%FindString.text = get_selected_text()
			%FindString.grab_focus()
		elif event.as_text_keycode() == "Ctrl+H":
			accept_event()
			%Find.visible = true
			%ReplaceControls.visible = true
			if get_selected_text() != "":
				%FindString.text = get_selected_text()
				%ReplaceString.grab_focus()
			else:
				%FindString.grab_focus()

func _on_close_pressed():
	%Find.visible = false

func update_find_occurrences():
	var find_string : String = %FindString.text
	var find_string_length : int = find_string.length()
	if find_string_length == 0:
		return
	var count : int = 0
	var current : int = 0
	var p : Vector2i = Vector2i(-1, 0)
	var caret_line : int = get_caret_line()
	var caret_column : int = get_caret_column()
	while true:
		var new_p : Vector2i = search(find_string, 0, p.y, p.x+1)
		if new_p.x == -1 and new_p.y == -1:
			break
		if not (new_p.y > p.y or new_p.y == p.y and new_p.x > p.x):
			break
		p = new_p
		count += 1
		if p.y == caret_line and caret_column >= p.x and caret_column <= p.x+find_string_length:
			current = count
	%FindOccurrences.text = "%d of %d" % [ current, count ]

func _on_find_string_changed(search_string : String):
	set_search_text(search_string)
	var p : Vector2i = search(search_string, 0, get_selection_line(), get_selection_column())
	if p.x != -1 and p.y != -1:
		print(p)
		select(p.y, p.x, p.y, p.x+search_string.length())
		set_caret_line(p.y)
		set_caret_column(p.x)
	update_find_occurrences()

func _on_previous_pressed():
	var search_string : String = %FindString.text
	var p : Vector2i
	if get_caret_column() == 0:
		if get_caret_line() == 0:
			p = search(search_string, TextEdit.SEARCH_BACKWARDS, get_line_count()-1, get_line(get_line_count()-1).length()-1)
		else:
			p = search(search_string, TextEdit.SEARCH_BACKWARDS, get_caret_line()-1, get_caret_column())
	else:
		p = search(search_string, TextEdit.SEARCH_BACKWARDS, get_caret_line(), get_caret_column()-1)
	if p.x != -1 and p.y != -1:
		select(p.y, p.x, p.y, p.x+search_string.length())
		set_caret_line(p.y)
		set_caret_column(p.x)
	grab_focus()
	update_find_occurrences()

func _on_next_pressed():
	var search_string : String = %FindString.text
	var p : Vector2i = search(search_string, 0, get_caret_line(), get_caret_column()+1)
	if p.x != -1 and p.y != -1:
		select(p.y, p.x, p.y, p.x+search_string.length())
		set_caret_line(p.y)
		set_caret_column(p.x)
	grab_focus()
	update_find_occurrences()

func _on_replace_current_pressed():
	var search_string : String = %FindString.text
	queue_redraw()
	var current_selection : String = get_line(get_caret_line()).substr(get_caret_column(), search_string.length())
	if current_selection == %FindString.text:
		begin_complex_operation()
		remove_text(get_caret_line(), get_caret_column(), get_caret_line(), get_caret_column()+search_string.length())
		insert_text_at_caret(%ReplaceString.text)
		end_complex_operation()
	_on_next_pressed()

func _on_replace_all_pressed():
	var search_string : String = %FindString.text
	var replace_string : String = %ReplaceString.text
	var p : Vector2i = Vector2i(0, 0)
	begin_complex_operation()
	while true:
		var new_p : Vector2i = search(search_string, 0, p.y, p.x)
		if new_p.x == -1 and new_p.y == -1:
			break
		if new_p.y < p.y or new_p.y == p.y and new_p.x < p.x:
			break
		p = new_p
		remove_text(p.y, p.x, p.y, p.x+search_string.length())
		set_caret_line(p.y)
		set_caret_column(p.x)
		insert_text_at_caret(replace_string)
		p.x += replace_string.length()
	end_complex_operation()
	update_find_occurrences()
