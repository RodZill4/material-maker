# This file is here so we can load it only when we are in the editor so that
# other places do not have to have "EditorInterface" in them, which causes a
# parser error when loaded outside of the editor.  The things we have to do in
# order to test things is annoying.
func get_it():
	return EditorInterface