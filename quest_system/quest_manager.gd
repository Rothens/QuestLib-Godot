class_name QuestManager
extends Node

var quest_users: Dictionary = {}  # user_id -> QuestUser 
var quest_defs: Dictionary = {}   # quest_id -> QuestDef
var starting_quests: Array = []
var loader = null
var db_manager = null

signal quest_progress_updated(user_id: int, quest_id: int)
signal quest_finished(user_id: int, quest_id: int)
signal quest_available(user_id: int, quest_id: int)
signal quest_accepted(user_id: int, quest_id: int)

func get_quest_user(user_id: int) -> QuestUser:
	if not quest_users.has(user_id):
		var qu = QuestUser.new(user_id, self)
		qu.add_available(starting_quests)
		quest_users[user_id] = qu
		
		if db_manager:
			db_manager.new_user(user_id)
	
	return quest_users[user_id]

func load_defs(p_loader) -> void:
	p_loader.load(quest_defs)
	loader = p_loader
		
	# Clear starting quests array before rebuilding it
	starting_quests.clear()
	
	for quest_id in quest_defs:
		var qd = quest_defs[quest_id]
		
		# Process prerequisites
		var has_valid_prereqs = true
		for prereq_id in qd.prerequisites:
			if not quest_defs.has(prereq_id):
				push_warning("Warning: Unresolved dependency (%d) for quest: %s" % [prereq_id, qd])
				has_valid_prereqs = false
			else:
				# Add this quest to the "touch" list of its prerequisite
				quest_defs[prereq_id].add_touch(qd.id)
		
		# If it has no prerequisites or they're all valid, add to starting quests
		if qd.prerequisites.is_empty():
			starting_quests.append(qd)

func load_progress(p_db_manager) -> void:
	db_manager = p_db_manager
	var data = db_manager.get_all_user_data()
	
	for qu in data:
		quest_users[qu.id] = qu

func get_defs() -> Array:
	return quest_defs.values()

func get_def(quest_id: int) -> QuestDef:
	if quest_defs.has(quest_id):
		return quest_defs[quest_id]
	return null

func notify(user_id: int, subject: QuestSubject, req_type: int, count: int) -> void:
	var qu = get_quest_user(user_id)
	if qu:
		qu.notify(subject, req_type, count)

func update_progress(qu: QuestUser, quest: Quest) -> void:
	if db_manager:
		db_manager.update_progress(qu, quest)
	
	quest_progress_updated.emit(qu.id, quest.def.id)

func set_available(qu: QuestUser, quest_id: int) -> void:
	if db_manager:
		db_manager.set_available(qu, quest_id)
	
	quest_available.emit(qu.id, quest_id)

func set_finished(qu: QuestUser, quest: Quest) -> void:
	if db_manager:
		db_manager.finish_quest(qu, quest)
	
	quest_finished.emit(qu.id, quest.def.id)

func accept_quest(user_id: int, quest_id: int) -> void:
	var qu = get_quest_user(user_id)
	var qd = get_def(quest_id)
	
	if qu == null or qd == null:
		return
		
	var quest = qu.accept_quest(qd)
	if quest != null:
		if db_manager:
			db_manager.accept_quest(qu, quest)
		
		quest_accepted.emit(user_id, quest_id)
