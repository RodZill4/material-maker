extends Node


var steam_api
var is_subscribed : bool = false
var avatar_texture : ImageTexture
var got_avatar : bool = false


signal avatar_ready()


func _ready():
	if not Engine.has_singleton("Steam"):
		return
	steam_api = Engine.get_singleton("Steam")
	var initialize_response: Dictionary = steam_api.steamInitEx()
	print("Did Steam initialize?: %s " % initialize_response)
	steam_api.initAuthentication()
	is_subscribed = steam_api.isSubscribed()

func is_owned() -> bool:
	return is_subscribed

func get_user_name() -> String:
	if not is_subscribed:
		return ""
	return steam_api.getPersonaName()

func get_avatar_texture() -> ImageTexture:
	if not is_subscribed:
		return null
	if not got_avatar:
		steam_api.avatar_loaded.connect(self._on_avatar_loaded)
		steam_api.getPlayerAvatar()
		await avatar_ready
	return avatar_texture

func _on_avatar_loaded(_user_id : int, avatar_size : int, avatar_buffer : PackedByteArray) -> void:
	# Create the image and texture for loading
	var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)

	# Optionally resize the image if it is too large
	if avatar_size > 128:
		avatar_image.resize(128, 128, Image.INTERPOLATE_LANCZOS)

	# Apply the image to a texture
	avatar_texture = ImageTexture.create_from_image(avatar_image)
	
	avatar_ready.emit()

func is_achievement_unlocked(achievement : String) -> bool:
	if not is_subscribed:
		return false
	var achievement_status : Dictionary = steam_api.getAchievement(achievement)
	if not achievement_status.ret:
		print_debug("Achievement ", achievement, " does not exist.")
		return false
	return steam_api.getAchievement(achievement).achieved

func unlock_achievement(achievement : String):
	if not is_subscribed:
		return
	var achievement_status : Dictionary = steam_api.getAchievement(achievement)
	if not achievement_status.ret:
		print_debug("Achievement ", achievement, " does not exist.")
		return
	if steam_api.getAchievement(achievement).achieved:
		return
	steam_api.setAchievement(achievement)
	steam_api.storeStats()

func increase_stat(stat : String, increment : int = 1):
	if not is_subscribed:
		return
	var stat_value = steam_api.getStatInt(stat)
	steam_api.setStatInt(stat, stat_value+increment)
