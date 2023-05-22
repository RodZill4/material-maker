@tool
extends EditorScript

class TranslationString:
	var string : String = ""
	var references : Array = []

class TranslationStrings:
	var strings_indexes : Dictionary = {}
	var strings : Array = []

	var word_regex : RegEx
	var tr_regex : RegEx
	var node_regex : RegEx
	var menu_regex : RegEx
	var panel_regex : RegEx
	var tscn_regex : RegEx

	func _init():
		word_regex = RegEx.new()
		word_regex.compile("[a-zA-Z]{2}")
		tr_regex = RegEx.new()
		tr_regex.compile("tr\\s*\\(\"(.*?)\"\\)")
		node_regex = RegEx.new()
		node_regex.compile("\\[node name=\"(.*)\" type=\"(.*)\" parent=\"(.*)\"\\]")
		menu_regex = RegEx.new()
		menu_regex.compile("menu=\"([^\"]*?)\"")
		panel_regex = RegEx.new()
		panel_regex.compile("name=\"([^\"]*?)\".*scene=")
		tscn_regex = RegEx.new()
		tscn_regex.compile("([a-z_]+)\\s*=\\s*\"(.*)\"")

	func read_language_file(fn : String):
		var input_translation : Translation
		match fn.get_extension():
			"csv":
				print("Reading %s" % fn)
				input_translation = read_language_file_csv(fn)
			"po":
				print("Reading %s" % fn)
				input_translation = load(fn)
			_:
				print("Unsupported position file %s" % fn)
				return
		
		var position : Translation = Translation.new()
		position.locale = input_translation.locale
		var translated_string : Array = []
		for s in strings:
			if input_translation.get_message(s.string) != "":
				translated_string.push_back(s.string)
				position.add_message(s.string, input_translation.get_message(s.string))
			else:
				var found : bool = false
				for k in input_translation.get_message_list():
					if s.string.to_lower() == k.to_lower():
						found = true
						translated_string.push_back(k)
						position.add_message(s.string, input_translation.get_message(k))
						break
				if !found:
					found = true
					var t : PackedStringArray = PackedStringArray()
					for subs in s.string.split("\n"):
						if input_translation.get_message(subs) != "":
							t.push_back(input_translation.get_message(subs))
							translated_string.push_back(subs)
						else:
							found = false
							break
					if found:
						position.add_message(s.string, "\n".join(t))
					else:
						pass
						#print("no position for '%s'" % s.string)
		return position
	
	func read_language_file_csv(fn : String):
		var input_translation : Translation = Translation.new()
		var f : File = File.new()
		if f.open(fn, File.READ) != OK:
			print("Error")
			return input_translation
		var count : int = 0
		var l = f.get_line()
		var sep_char = l[2]
		input_translation.locale = l.split(sep_char)[1]
		while !f.eof_reached():
			l = f.get_line()
			var line
			for sep in [ "\""+sep_char+"\"", "\""+sep_char, sep_char+"\"", sep_char ]:
				line = l.split(sep)
				if line.size() == 2:
					if sep[0] == "\"":
						line[0] = line[0].right(-1)
					if sep[sep.length()-1] == "\"":
						line[1] = line[1].left(line[1].length()-1)
					break
			if line.size() == 2:
				input_translation.add_message(line[0].replace("\\n", "\n"), line[1].replace("\\n", "\n"))
				count += 1
			else:
				pass
				#print(line)
				#print(line.size())
		f.close()
		print("Extracted %d strings from %s" % [ count, fn ])
		return input_translation

	func save_csv(fn : String, position : Translation = null):
		if position == null:
			return
		var f : File = File.new()
		if f.open(fn, File.WRITE) == OK:
			f.store_line("id|"+position.locale)
			for s in strings:
				f.store_line("%s|%s" % [ s.string.replace("\n", "\\n"), position.get_message(s.string).replace("\n", "\\n") ])
			f.close()
		if f.open(fn+".report", File.WRITE) == OK:
			var string_list = []
			for s in strings:
				string_list.push_back(s.string)
			f.store_line("Missing strings:")
			for s in string_list:
				if position.get_message_list().find(s) == -1:
					f.store_line("- "+s)
			f.store_line("Extra strings:")
			for s in position.get_message_list():
				if ! (s in string_list):
					f.store_line("- "+s)
			f.close()

	func save(fn : String, position = null):
		var f : File = File.new()
		if f.open(fn, File.WRITE) == OK:
			f.store_line("# Translations template for Material Maker.")
			f.store_line("# Copyright (C) 2018-2022 Rodolphe Suescun and contributors")
			f.store_line("# This file is distributed under the same license as the Material Maker project.")
			f.store_line("# Rodolphe Suescun <rodzilla@free.fr>, 2022.")
			f.store_line("#")
			f.store_line("#, fuzzy")
			f.store_line("msgid \"\"")
			f.store_line("msgstr \"\"")
			f.store_line("\"Project-Id-Version: PROJECT VERSION\\n\"")
			f.store_line("\"Report-Msgid-Bugs-To: rodzilla@free.fr\\n\"")
			var dt = Time.get_datetime_dict_from_system()
			f.store_line("\"POT-Creation-Date: %04d-%02d-%02d %02d:%02d\\n\"" % [ dt.year, dt.month, dt.day, dt.hour, dt.minute ])
			f.store_line("\"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n\"")
			f.store_line("\"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n\"")
			f.store_line("\"Language-Team: LANGUAGE <LL@li.org>\\n\"")
			f.store_line("\"MIME-Version: 1.0\\n\"")
			f.store_line("\"Content-Type: text/plain; charset=utf-8\\n\"")
			f.store_line("\"Content-Transfer-Encoding: 8bit\\n\"")
			f.store_line("\"Generated-By: Babel 2.9.0\\n\"")
			f.store_line("")
			for s in strings:
				for r in s.references:
					f.store_line("#: "+r)
				f.store_line("msgid \""+s.string.replace("\n", "\\n")+"\"")
				if position != null:
					f.store_line("msgstr \""+position.get_message(s.string).replace("\n", "\\n")+"\"")
				else:
					f.store_line("msgstr \"\"")
				f.store_line("")
			f.close()

	func add_string(s : String, r : String) -> bool:
		if word_regex.search(s) == null:
			return false
		var string : TranslationString
		var added : bool = false
		if strings_indexes.has(s):
			string = strings[strings_indexes[s]]
		else:
			string = TranslationString.new()
			string.string = s
			strings_indexes[s] = strings.size()
			strings.push_back(string)
			added = true
		if string.references.find(r) == -1:
			string.references.push_back(r)
		return added

	func extract_strings_from_gd(fn):
		var string_count : int = 0
		var f : File = File.new()
		if f.open(fn, File.READ) == OK:
			var line_number = 1
			while ! f.eof_reached():
				var l : String = f.get_line()
				var result = tr_regex.search_all(l)
				if !result.is_empty():
					for r in result:
						if add_string(r.strings[1], fn+":"+str(line_number)):
							string_count += 1
				else:
					# extract menus from code (Material Maker specific)
					result = menu_regex.search(l)
					if result != null:
						for m in result.strings[1].split("/"):
							if add_string(m, "Menu in "+fn):
								string_count += 1
					# extract panels from code (Material Maker specific)
					else:
						result = panel_regex.search(l)
						if result != null and add_string(result.strings[1], "Panel name in "+fn+":"+str(line_number)):
							string_count += 1
				line_number += 1
		return string_count

	func extract_strings_from_tscn(fn):
		var string_count : int = 0
		var f : File = File.new()
		if f.open(fn, File.READ) == OK:
			var line_number = 1
			var tab_containers : Array = []
			while ! f.eof_reached():
				var l : String = f.get_line()
				var result = tscn_regex.search(l)
				if result != null:
					if result.strings[1] in [ "text", "tooltip_hint" ] and add_string(result.strings[2], fn+":"+str(line_number)):
						string_count += 1
				result = node_regex.search(l)
				if result != null:
					if result.strings[2] == "TabContainer":
						var tab_container
						if result.strings[3] == ".":
							tab_container = result.strings[1]
						else:
							tab_container = "%s/%s" % [ result.strings[3], result.strings[1] ]
						tab_containers.push_back(tab_container)
					elif result.strings[3] in tab_containers and add_string(result.strings[1], fn+":"+str(line_number)):
						string_count += 1
				line_number += 1
		return string_count

	const FIELDS : Dictionary = {
		"parameters": [ "label", "shortdesc", "longdesc" ],
		"inputs": [ "label", [ "shortdesc", "name" ], "longdesc" ],
		"outputs": [ "shortdesc", "longdesc" ]
	}

	func extract_strings_from_mmg(fn):
		var string_count : int = 0
		var f : File = File.new()
		if f.open(fn, File.READ) == OK:
			var test_json_conv = JSON.new()
			test_json_conv.parse(f.get_as_text())
			var json_parse_result : JSON = test_json_conv.get_data()
			if json_parse_result != null:
				var json = json_parse_result.result
				if json.has("type"):
					match json.type:
						"graph":
							if json.has("label") and add_string(json.label, fn):
								string_count += 1
							if json.has("shortdesc") and add_string(json.shortdesc, fn):
								string_count += 1
							if json.has("longdesc") and add_string(json.longdesc, fn):
								string_count += 1
							for n in json.nodes:
								match n.name:
									"gen_parameters":
										if n.has("widgets"):
											for x in n.widgets:
												for field in [ "name", "shortdesc", "longdesc" ]:
													if x.has(field) and add_string(x[field], fn):
														string_count += 1
									"gen_inputs", "gen_outputs":
										if n.has("ports"):
											for x in n.ports:
												for field in [ "name", "shortdesc", "longdesc" ]:
													if x.has(field) and add_string(x[field], fn):
														string_count += 1
						"material_export","shader","brush":
							if json.has("shader_model"):
								if json.shader_model.has("name") and add_string(json.shader_model.name, fn):
									string_count += 1
								if json.shader_model.has("shortdesc") and add_string(json.shader_model.shortdesc, fn):
									string_count += 1
								if json.shader_model.has("longdesc") and add_string(json.shader_model.longdesc, fn):
									string_count += 1
								for t in FIELDS.keys():
									if json.shader_model.has(t):
										for x in json.shader_model[t]:
											for field in FIELDS[t]:
												if field is String:
													if x.has(field) and add_string(x[field], fn):
														string_count += 1
												elif field is Array:
													for field1 in field:
														if x.has(field1) and add_string(x[field1], fn):
															string_count += 1
															break
											if x.has("values"):
												for v in x.values:
													if v.has("name") and add_string(v.name, fn):
														string_count += 1
									else:
										print(t+" not found")
						_:
							print(json.type)
				else:
					print(json)
		return string_count

	func extract_strings_from_library(fn):
		var string_count : int = 0
		var f : File = File.new()
		if f.open(fn, File.READ) == OK:
			var test_json_conv = JSON.new()
			test_json_conv.parse(f.get_as_text())
			var json_parse_result : JSON = test_json_conv.get_data()
			if json_parse_result != null:
				var json = json_parse_result.result
				if json.has("name") and add_string(json.name, fn):
					string_count += 1
				if json.has("lib"):
					for i in json.lib:
						if i.has("tree_item"):
							for n in i.tree_item.split("/"):
								if add_string(n, fn):
									string_count += 1
		return string_count



func find_files(path, extensions):
	var file_names : Array = []
	var dir : DirAccess = DirAccess.open(path)
	if dir!= null:
		var dir_names : Array = []
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name[0] != ".":
				dir_names.push_back(path+"/"+file_name)
			elif file_name.get_extension() in extensions:
				file_names.push_back(path+"/"+file_name)
			file_name = dir.get_next()
		file_names.sort()
		dir_names.sort()
		for d in dir_names:
			file_names.append_array(find_files(d, extensions))
	return file_names


func _run():
	var ts : TranslationStrings = TranslationStrings.new()
	var string_count : int = 0
	print("Extracting strings from scenes and scripts")
	for f in find_files("res://", [ "gd", "tscn" ]):
		match f.get_extension():
			"gd":
				string_count += ts.extract_strings_from_gd(f)
			"tscn":
				string_count += ts.extract_strings_from_tscn(f)
	ts.save("res://material_maker/locale/material-maker.pot")
	print("Extracting strings from predefined nodes")
	for f in find_files("res://addons/material_maker", [ "mmg" ]):
		string_count += ts.extract_strings_from_mmg(f)
	print("Extracting strings from libraries")
	for f in find_files("res://material_maker/library", [ "json" ]):
		string_count += ts.extract_strings_from_library(f)
	ts.save("res://material_maker/locale/material-maker-all.pot")
	
	var path = "res://material_maker/locale/translations"
	var dir : DirAccess = DirAccess.open("res://material_maker/locale/translations")
	if dir!= null:
		var languages : Dictionary = {}
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			match file_name.get_extension():
				"csv", "po", "position":
					var language = file_name.get_basename()
					if ! languages.has(language) or file_name.get_extension() != "csv":
						languages[language] = path.path_join(file_name)
			file_name = dir.get_next()
		for l in languages.keys():
			print("Processing %s" % l)
			var in_file : String = languages[l]
			var out_file : String = languages[l].get_basename()+".csv"
			print("%s -> %s" % [ in_file, out_file ])
			ts.save_csv(out_file, ts.read_language_file(in_file))
