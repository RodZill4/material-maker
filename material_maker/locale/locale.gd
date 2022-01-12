extends Object

const LOCALE_DIR: String = "user://locale"


func install_translation(fn: String):
	var dir: Directory = Directory.new()
	dir.make_dir_recursive(LOCALE_DIR)
	if dir.copy(fn, LOCALE_DIR.plus_file(fn.get_file())) == OK:
		read_translations()


func add_translations(dest: Translation, src: Translation):
	for m in src.get_message_list():
		dest.add_message(m, src.get_message(m))


func read_translations():
	var translations: Dictionary = {}
	var dir = Directory.new()
	if dir.open(LOCALE_DIR) == OK:
		var csv_files: Array = []
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				match file_name.get_extension():
					"po", "translation":
						var t: Translation = load(LOCALE_DIR.plus_file(file_name))
						if translations.has(t.locale):
							add_translations(translations[t.locale], t)
						else:
							translations[t.locale] = t
							TranslationServer.add_translation(t)
					"csv":
						csv_files.push_back(file_name)
			file_name = dir.get_next()
		for fn in csv_files:
			var f: File = File.new()
			if f.open(LOCALE_DIR.plus_file(fn), File.READ) == OK:
				var l: String = f.get_line()
				if l.left(2) == "id":
					var separator = l[2]
					var languages: Array = l.split(separator)
					languages[0] = null
					for i in range(1, languages.size()):
						if languages[i] == "en":
							languages[i] = null
						else:
							if translations.has(languages[i]):
								languages[i] = translations[languages[i]]
							else:
								var translation: Translation = Translation.new()
								translation.locale = languages[i]
								translations[languages[i]] = translation
								languages[i] = translation
								TranslationServer.add_translation(translation)
					while !f.eof_reached():
						l = f.get_line()
						var strings: Array = l.split(separator)
						if strings.size() == languages.size():
							for i in range(1, languages.size()):
								if languages[i] != null:
									languages[i].add_message(
										strings[0].replace("\\n", "\n"),
										strings[i].replace("\\n", "\n")
									)
				f.close()
