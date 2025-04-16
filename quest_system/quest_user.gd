class_name QuestUser
extends RefCounted

var id: int
var finished_quests = []
var in_progress_quests = {}
var available = []
var manager

func _init(p_id: int, p_manager, p_finished_quests = [], 
		p_in_progress_quests = {}, p_available = []):
	id = p_id
	manager = p_manager
	finished_quests = p_finished_quests
	in_progress_quests = p_in_progress_quests
	available = p_available

func notify(quest_subject: QuestSubject, req_type: int, count: int) -> void:
	var finished = []
	
	for quest_id in in_progress_quests:
		var quest = in_progress_quests[quest_id]
		if quest.is_related(quest_subject, req_type):
			if quest.notify(quest_subject, req_type, count):
				finished.append(quest)
				finished_quests.append(quest.def.id)
			
			manager.update_progress(self, quest)
	
	for quest in finished:
		in_progress_quests.erase(quest.def.id)
		manager.set_finished(self, quest)
		
		for touch_id in quest.def.touch:
			var qd = manager.get_def(touch_id)
			if qd != null and not qd in available:
				var all_prereqs_met = true
				for prereq in qd.prerequisites:
					if not prereq in finished_quests:
						all_prereqs_met = false
						break
				
				if all_prereqs_met:
					available.append(qd)
					manager.set_available(self, qd.id)

func accept_quest(quest_def: QuestDef) -> Quest:
	if not quest_def in available:
		return null
	
	var idx = available.find(quest_def)
	if idx >= 0:
		available.remove_at(idx)
	
	var new_quest = quest_def.create_quest()
	in_progress_quests[quest_def.id] = new_quest
	return new_quest

func add_available(new_quests) -> void:
	for quest in new_quests:
		if not quest in available:
			available.append(quest)
