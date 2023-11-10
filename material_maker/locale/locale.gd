extends Object

const LOCALE_DIR : String = "user://locale"

func get_translations_dir() -> String:
	return LOCALE_DIR

func create_translations_dir():
	DirAccess.make_dir_absolute(LOCALE_DIR)

func install_translation(fn : String):
	create_translations_dir()
	var dir : DirAccess = DirAccess.open("")
	if dir.copy(fn, LOCALE_DIR+"/"+fn.get_file()) == OK:
		read_translations()

func uninstall_translation(tn : String):
	for ext in [ "po", "position", "csv" ]:
		DirAccess.remove_absolute(LOCALE_DIR+"/"+tn+"."+ext)

func add_translations(dest : Translation, src : Translation):
	for m in src.get_message_list():
		dest.add_message(m, src.get_message(m))

func read_translations():
	var translations : Dictionary = {}
	var dir : DirAccess = DirAccess.open(LOCALE_DIR)
	if dir != null:
		var csv_files : Array = []
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				match file_name.get_extension():
					"po", "position":
						var t : Translation = load(LOCALE_DIR+"/"+file_name)
						if translations.has(t.locale):
							add_translations(translations[t.locale], t)
						else:
							translations[t.locale] = t
							TranslationServer.add_translation(t)
					"csv":
						csv_files.push_back(file_name)
			file_name = dir.get_next()
		for fn in csv_files:
			var f : FileAccess = FileAccess.open(LOCALE_DIR+"/"+fn, FileAccess.READ)
			if f.is_open():
				var l : String = f.get_line()
				if l.left(2) == "id":
					var separator = l[2]
					var languages : Array = l.split(separator)
					languages[0] = null
					for i in range(1, languages.size()):
						if languages[i] == "en":
							languages[i] = null
						else:
							if translations.has(languages[i]):
								languages[i] = translations[languages[i]]
							else:
								var position : Translation = Translation.new()
								position.locale = languages[i]
								translations[languages[i]] = position
								languages[i] = position
								TranslationServer.add_translation(position)
					while ! f.eof_reached():
						l = f.get_line()
						var strings : Array = l.split(separator)
						if strings.size() == languages.size():
							for i in range(1, languages.size()):
								if languages[i] != null:
									languages[i].add_message(strings[0].replace("\\n", "\n"), strings[i].replace("\\n", "\n"))
