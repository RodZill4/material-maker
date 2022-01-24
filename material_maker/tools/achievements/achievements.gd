extends Node


var unlocked : Array = []
var achievement_list = preload("res://material_maker/tools/achievements/achievement_list.gd")

var config = null

func set_config(config_cache):
	config = config_cache
	if config.has_section_key("achievements", "unlocked"):
		unlocked = config.get_value("achievements", "unlocked").split(",")
	unlock("ui_start")

func unlock(achievement : String):
	if unlocked.find(achievement) != -1:
		return
	unlocked.push_back(achievement)
	config.set_value("achievements", "unlocked", PoolStringArray(unlocked).join(","))
	for s in achievement_list.ACHIEVEMENTS:
		for a in s.achievements:
			if achievement == a.id:
				var achievement_widget = load("res://material_maker/tools/achievements/new_achievement.tscn").instance()
				achievement_widget.set_texts(a.name, a.description)
				add_child(achievement_widget)
				return
