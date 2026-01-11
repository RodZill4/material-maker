# ------------------------------------------------------------------------------
# There was an error that someone found in Godot 4.4.1, but ended up being a
# different error in Godot 4.5.  The fix was to hold a reference to the font
# so that TextEdit control did not lose the font when switching.  This is
# the solution I came up with.  Just hold a reference to all fonts we use,
# but only when we use them.  Basically a lazy loader with some semantics for
# font names and location.
#
# https://github.com/bitwes/Gut/issues/749
#
# An instance of this could be used to allow users to specify their own fonts.
# It's not perect for that yet, but it is feasible.
# ------------------------------------------------------------------------------
const DEFAULT_CUSTOM_FONT_NAME = 'CourierPrime'
const THEME_FONT_TO_FONT_TYPES_MAP = {
	'font':FONT_TYPES.REGULAR,
	'normal_font': FONT_TYPES.REGULAR,
	'bold_font': FONT_TYPES.BOLD,
	'italics_font':FONT_TYPES.ITALIC,
	'bold_italics_font':FONT_TYPES.BOLD_ITALIC
}


# Values for FONT_TYPES are based on Google font file suffix (not extension).
# A font file will be a key from fonts + - + FONT_TYPE value + .ttf.
const FONT_TYPES = {
	REGULAR = 'Regular',
	BOLD = 'Bold',
	ITALIC = 'Italic',
	BOLD_ITALIC = 'BoldItalic'
}


var fonts = {
	'AnonymousPro':{},
	'CourierPrime':{},
	'LobsterTwo':{},
	'Default':{}
}


var custom_font_path = 'res://addons/gut/fonts/'


func _init():
	_populate_default_fonts()


func _populate_default_fonts():
	var ctrl = TextEdit.new()
	var f = ctrl.get_theme_font('font')
	for key in FONT_TYPES:
		fonts['Default'][FONT_TYPES[key]] = f
	ctrl.free()


func _load_font(font_name, font_type, font_path):
	var dynamic_font = FontFile.new()
	dynamic_font.load_dynamic_font(font_path)
	fonts[font_name][font_type] = dynamic_font


func get_font(font_name, font_type='Regular'):
	if(!fonts.has(font_name)):
		push_error(str("Invalid font name '", font_name, "'"))
		return fonts['Default'][FONT_TYPES.REGULAR]

	if(!FONT_TYPES.values().has(font_type)):
		push_error(str("Invalid font type '", font_type, "'"))
		return fonts['Default'][FONT_TYPES.REGULAR]

	if(!fonts[font_name].has(font_type)):
		var filename = custom_font_path.path_join(str(font_name, '-', font_type, '.ttf'))
		if(FileAccess.file_exists(filename)):
			_load_font(font_name, font_type, filename)
		else:
			push_error(str("Missing custom font ", filename))
			return fonts['Default'][FONT_TYPES.REGULAR]

	return fonts.get(font_name, {}).get(font_type, null)


func get_font_names():
	return fonts.keys()


# Maps the various theme font names (font, normal_font, italics_font etc) to
# a FONT_TYPE.
func get_font_for_theme_font_name(theme_font_name, custom_font_name):
	if(!THEME_FONT_TO_FONT_TYPES_MAP.has(theme_font_name)):
		push_error(str("Unknown theme font name ", theme_font_name))
		return get_font(custom_font_name)
	return get_font(custom_font_name, THEME_FONT_TO_FONT_TYPES_MAP[theme_font_name])

