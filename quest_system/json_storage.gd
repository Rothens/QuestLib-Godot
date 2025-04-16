class_name QuestJsonStorage
extends RefCounted

var save_dir: String
var quest_manager

func _init(p_save_dir: String, p_quest_manager):
	save_dir = p_save_dir
	quest_manager = p_quest_manager
	
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists(save_dir):
		dir.make_dir_recursive(save_dir)

func get_user_data(user_id: int) -> QuestUser:
	var file_path = "%s/user_%d.json" % [save_dir, user_id]
	if not FileAccess.file_exists(file_path):
		return null
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open file: %s" % file_path)
		return null
		
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("Error parsing user data JSON: %s" % json.get_error_message())
		return null
	
	var data = json.data
	
	var finished = []
	var available = []
	var progress = {}
	
	if data.has("finished_quests") and data.finished_quests is Array:
		for quest_id in data.finished_quests:
			finished.append(int(quest_id))
	
	if data.has("available") and data.available is Array:
		for quest_id in data.available:
			var quest_def = quest_manager.get_def(int(quest_id))
			if quest_def:
				available.append(quest_def)
	
	if data.has("in_progress") and data.in_progress is Dictionary:
		for quest_id_str in data.in_progress:
			var quest_id = int(quest_id_str)
			var quest_def = quest_manager.get_def(quest_id)
			if quest_def:
				var quest = Quest.new(quest_def)
				if data.in_progress[quest_id_str] is Dictionary:
					for req_hash_str in data.in_progress[quest_id_str]:
						var req_hash = int(req_hash_str)
						var count = int(data.in_progress[quest_id_str][req_hash_str])
						quest.set_request(req_hash, count)
				progress[quest_id] = quest
	
	return QuestUser.new(user_id, quest_manager, finished, progress, available)

func get_all_user_data() -> Array:
	var users = []
	var dir = DirAccess.open(save_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.begins_with("user_") and file_name.ends_with(".json"):
				var user_id_str = file_name.replace("user_", "").replace(".json", "")
				var user_id = int(user_id_str)
				var user = get_user_data(user_id)
				if user:
					users.append(user)
			file_name = dir.get_next()
	
	return users

func finish_quest(qu: QuestUser, quest: Quest) -> void:
	save_user_data(qu)

func update_progress(qu: QuestUser, quest: Quest) -> void:
	save_user_data(qu)

func set_available(qu: QuestUser, quest_id: int) -> void:
	save_user_data(qu)

func clear() -> void:
	var dir = DirAccess.open(save_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				dir.remove(file_name)
			file_name = dir.get_next()

func new_user(user_id: int) -> QuestUser:
	var qu = QuestUser.new(user_id, quest_manager)
	var starting_quests = quest_manager.starting_quests
	qu.add_available(starting_quests)
	save_user_data(qu)
	return qu

func accept_quest(qu: QuestUser, quest: Quest) -> void:
	save_user_data(qu)

func save_user_data(user: QuestUser) -> void:
	var data = {
		"id": user.id,
		"finished_quests": [],
		"available": [],
		"in_progress": {}
	}
	
	for quest_id in user.finished_quests:
		data.finished_quests.append(quest_id)
	
	for quest_def in user.available:
		data.available.append(quest_def.id)
	
	for quest_id in user.in_progress_quests:
		var quest = user.in_progress_quests[quest_id]
		data.in_progress[str(quest_id)] = {}
		for req_hash in quest.cnt:
			data.in_progress[str(quest_id)][str(req_hash)] = quest.cnt[req_hash]
	
	var file_path = "%s/user_%d.json" % [save_dir, user.id]
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
	else:
		push_error("Failed to open file for writing: %s" % file_path)
