extends Node


var is_subscribed : bool = false
var avatar_texture : ImageTexture
var got_avatar : bool = false


signal avatar_ready()


func _ready():
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam initialize?: %s " % initialize_response)
	Steam.initAuthentication()
	is_subscribed = Steam.isSubscribed()
	#Steam.avatar_loaded.connect(self._on_avatar_loaded)
	#Steam.getPlayerAvatar()
	#Steam.connect("leaderboard_find_result", self, "_on_leaderboard_find_result")
	#Steam.connect("leaderboard_score_uploaded", self, "_on_leaderboard_score_uploaded")
	#Steam.connect("leaderboard_scores_downloaded", self, "_on_leaderboard_scores_downloaded")
	Steam.findLeaderboard("Node count")

func is_owned() -> bool:
	return is_subscribed

func get_user_name() -> String:
	if not is_subscribed:
		return ""
	return Steam.getPersonaName()

func get_avatar_texture() -> ImageTexture:
	if not is_subscribed:
		return null
	if not got_avatar:
		Steam.avatar_loaded.connect(self._on_avatar_loaded)
		Steam.getPlayerAvatar()
		await avatar_ready
	return avatar_texture

func _on_avatar_loaded(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
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
	var achievement_status : Dictionary = Steam.getAchievement(achievement)
	if not achievement_status.ret:
		print("Achievement ", achievement, " does not exist.")
		return false
	return Steam.getAchievement(achievement).achieved

func unlock_achievement(achievement : String):
	if not is_subscribed:
		return
	Steam.setAchievement(achievement)
