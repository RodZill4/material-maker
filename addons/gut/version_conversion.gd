class ConfigurationUpdater:
	var EditorGlobals = load("res://addons/gut/gui/editor_globals.gd")

	func warn(message):
		print('GUT Warning:  ', message)

	func info(message):
		print("GUT Info:  ", message)

	func moved_file(from, to):
		if(FileAccess.file_exists(from) and !FileAccess.file_exists(to)):
			info(str('Copying [', from, '] to [', to, ']'))
			var result = DirAccess.copy_absolute(from, to)
			if(result != OK):
				warn(str('Could not copy [', from, '] to [', to, ']'))

		if(FileAccess.file_exists(from) and FileAccess.file_exists(to)):
			warn(str('File [', from, '] has been moved to [', to, "].\n    You can delete ", from))


	func move_user_file(from, to):
		if(from.begins_with('user://') and to.begins_with('user://')):
			if(FileAccess.file_exists(from) and !FileAccess.file_exists(to)):
				info(str('Moving [', from, '] to [', to, ']'))
				var result = DirAccess.copy_absolute(from, to)
				if(result == OK):
					info(str('    ', 'Created ', to))
					result = DirAccess.remove_absolute(from)
					if(result != OK):
						warn(str('    ', 'Could not delete ', from))
					else:
						info(str('    ', 'Deleted ', from))
				else:
					warn(str('    ', 'Could not copy [', from, '] to [', to, ']'))
		else:
			warn(str('Attempt to move_user_file with files not in user:// ', from, '->', to))


	func remove_user_file(which):
		if(which.begins_with('user://') and FileAccess.file_exists(which)):
			info(str('Deleting obsolete file ', which))
			var result = DirAccess.remove_absolute(which)
			if(result != OK):
				warn(str('    ', 'Could not delete ', which))
			else:
				info(str('    ', 'Deleted ', which))

class v9_2_0:
	extends ConfigurationUpdater

	func validate():
		moved_file('res://.gut_editor_config.json', EditorGlobals.editor_run_gut_config_path)
		moved_file('res://.gut_editor_shortcuts.cfg', EditorGlobals.editor_shortcuts_path)
		remove_user_file('user://.gut_editor.bbcode')
		remove_user_file('user://.gut_editor.json')


static func convert():
	var inst = v9_2_0.new()
	inst.validate()