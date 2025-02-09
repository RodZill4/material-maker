extends Object

func on_error(shader : String, error_message : String) -> void:
	var error_list = error_message.split("\n")
	var code_lines = shader.split("\n")
	mm_logger.error("shader error: "+error_list[0])
	for ei in range(1, error_list.size()):
		var error_location = error_list[ei].split(":", true, 3)
		if error_location.size() < 4:
			continue
		for fi in error_location.size():
			error_location[fi] = error_location[fi].strip_edges()
		if error_location[3] == "\'\' : compilation terminated":
			continue
		var location : String = ""
		var line : int =  error_location[2].to_int()-1
		for l in range(line-1, 0, -1):
			if code_lines[l].find("// #") != -1:
				mm_logger.message(code_lines[l])
				var regex : RegEx = RegEx.create_from_string("// #(\\w+):\\s+([\\w_/]+)\\s\\((\\w+)\\)")
				var re_match = regex.search(code_lines[l])
				if re_match:
					location = "[[type:nodesection,node:%s,nodeid:%s,section:%s]]" % [re_match.strings[2], re_match.strings[3], re_match.strings[1]]
				break
		if location == "":
			mm_logger.message(error_location[3])
		else:
			mm_logger.message("In %s: %s" % [ location, error_location[3]])
		var line_from = max(line, 0)
		var line_to = min(line, code_lines.size()-1)
		for l in range(line_from, line_to+1):
			mm_logger.message("%d: %s" % [ l+1, code_lines[l] ])
