tool
extends EditorScript

class TranslationString:
	var string : String = ""
	var references : Array = []

class TranslationStrings:
	var strings_indexes : Dictionary = {}
	var strings : Array = []

	var word_regex : RegEx
	var tr_regex : RegEx
	var menu_regex : RegEx
	var panel_regex : RegEx
	var tscn_regex : RegEx

	func _init():
		word_regex = RegEx.new()
		word_regex.compile("[a-zA-Z]{2}")
		tr_regex = RegEx.new()
		tr_regex.compile("tr\\s*\\(\"(.*)\"\\)")
		menu_regex = RegEx.new()
		menu_regex.compile("menu=\"([^\"]*)\".*description=\"([^\"]*)")
		panel_regex = RegEx.new()
		panel_regex.compile("name=\"([^\"]*)\".*scene=")
		tscn_regex = RegEx.new()
		tscn_regex.compile("([a-z_]+)\\s*=\\s*\"(.*)\"")

	func read_language_file(fn : String):
		var f : File = File.new()
		if f.open(fn, File.READ) != OK:
			return null
		var file_strings : Dictionary = {}
		var count : int = 0
		while !f.eof_reached():
			var l : String = f.get_line()
			var line
			for sep in [ "\",\"", "\",", ",\"", "," ]:
				line = l.split(sep)
				if line.size() == 2:
					if sep[0] == "\"":
						line[0] = line[0].right(1)
					if sep[sep.length()-1] == "\"":
						line[1] = line[1].left(line[1].length()-1)
					break
			if line.size() == 2:
				file_strings[line[0].replace("\\n", "\n")] = line[1].replace("\\n", "\n")
				count += 1
			else:
				pass
				#print(l)
				#print(line)
				#print(line.size())
		f.close()
		print("Extracted %d strings from %s" % [ count, fn ])
		
		var translation : Translation = Translation.new()
		var translated_string : Array = []
		for s in strings:
			if file_strings.has(s.string):
				translated_string.push_back(s.string)
				translation.add_message(s.string, file_strings[s.string])
			else:
				var found : bool = false
				for k in file_strings.keys():
					if s.string.to_lower() == k.to_lower():
						found = true
						translated_string.push_back(k)
						translation.add_message(s.string, file_strings[k])
						break
				if !found:
					found = true
					var t : PoolStringArray = PoolStringArray()
					for subs in s.string.split("\n"):
						if file_strings.has(subs):
							t.push_back(file_strings[subs])
							translated_string.push_back(subs)
						else:
							found = false
							break
					if found:
						translation.add_message(s.string, t.join("\n"))
					else:
						pass
						print("no translation for '%s'" % s.string)
		return translation

	func save_csv(fn : String, translation = null):
		if translation == null:
			return
		var f : File = File.new()
		if f.open(fn, File.WRITE) == OK:
			f.store_line("id|zh")
			for s in strings:
				f.store_line("%s|%s" % [ s.string.replace("\n", "\\n"), translation.get_message(s.string).replace("\n", "\\n") ])
			f.close()

	func save(fn : String, translation = null):
		var f : File = File.new()
		if f.open(fn, File.WRITE) == OK:
			f.store_line("# Translations template for Material Maker.")
			f.store_line("# Copyright (C) 2021 Rodolphe Suescun and contributors")
			f.store_line("# This file is distributed under the same license as the Material Maker project.")
			f.store_line("# Rodolphe Suescun <rodzilla@free.fr>, 2021.")
			f.store_line("#")
			f.store_line("#, fuzzy")
			f.store_line("msgid \"\"")
			f.store_line("msgstr \"\"")
			f.store_line("\"Project-Id-Version: PROJECT VERSION\\n\"")
			f.store_line("\"Report-Msgid-Bugs-To: rodzilla@free.fr\\n\"")
			var dt = OS.get_datetime()
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
				if translation != null:
					f.store_line("msgstr \""+translation.get_message(s.string).replace("\n", "\\n")+"\"")
				else:
					f.store_line("msgstr \"\"")
				f.store_line("")
			f.close()

	func strings_to_clipboard():
		var c : String = ""
		for s in strings:
			c += s.string+";"+"\n"
		OS.clipboard = c

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
				var result = tr_regex.search(l)
				if result != null:
					if add_string(result.strings[1], fn+":"+str(line_number)):
						string_count += 1
				else:
					# extract menus from code (Material Maker specific)
					result = menu_regex.search(l)
					if result != null:
						for m in result.strings[1].split("/"):
							if add_string(m, fn):
								string_count += 1
						if add_string(result.strings[2], fn+":"+str(line_number)):
							string_count += 1
					# extract panels from code (Material Maker specific)
					else:
						result = panel_regex.search(l)
						if result != null and add_string(result.strings[1], fn+":"+str(line_number)):
							string_count += 1
				line_number += 1
		return string_count

	func extract_strings_from_tscn(fn):
		var string_count : int = 0
		var f : File = File.new()
		if f.open(fn, File.READ) == OK:
			var line_number = 1
			while ! f.eof_reached():
				var l : String = f.get_line()
				var result = tscn_regex.search(l)
				if result != null:
					if result.strings[1] in [ "text", "tooltip_hint" ] and add_string(result.strings[2], fn+":"+str(line_number)):
						string_count += 1
				line_number += 1
		return string_count

	const FIELDS : Dictionary = {
		"parameters": [ "label", "shortdesc", "longdesc" ],
		"inputs": [ "label", "shortdesc", "longdesc" ],
		"outputs": [ "shortdesc", "longdesc" ]
	}

	func extract_strings_from_mmg(fn):
		var string_count : int = 0
		var f : File = File.new()
		if f.open(fn, File.READ) == OK:
			var json_parse_result : JSONParseResult = JSON.parse(f.get_as_text())
			if json_parse_result != null:
				var json = json_parse_result.result
				if json.has("type"):
					match json.type:
						"graph":
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
						"material_export","shader":
							if json.has("shader_model"):
								if json.shader_model.has("shortdesc") and add_string(json.shader_model.shortdesc, fn):
									string_count += 1
								if json.shader_model.has("longdesc") and add_string(json.shader_model.longdesc, fn):
									string_count += 1
								for t in [ "parameters", "inputs", "outputs" ]:
									if json.shader_model.has(t):
										for x in json.shader_model[t]:
											for field in FIELDS[t]:
												if x.has(field) and add_string(x[field], fn):
													string_count += 1
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
			var json_parse_result : JSONParseResult = JSON.parse(f.get_as_text())
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
	var dir = Directory.new()
	if dir.open(path) == OK:
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
	print("Extracting strings from predefined nodes")
	for f in find_files("res://addons/material_maker", [ "mmg" ]):
		string_count += ts.extract_strings_from_mmg(f)
	print("Extracting strings from libraries")
	for f in find_files("res://material_maker/library", [ "json" ]):
		string_count += ts.extract_strings_from_library(f)
	ts.save("res://material_maker/locale/material-maker.pot")
	ts.strings_to_clipboard()
	ts.save_csv("user://locale/zh.csv", ts.read_language_file("user://locale/zh_translation_utf_8.csv"))
	
