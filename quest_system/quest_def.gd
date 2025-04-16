class_name QuestDef
extends RefCounted

var id: int
var description: String
var ongoing: String
var onfinished: String
var prerequisites: Array = []
var touch: Array = []
var quest_givers: Array = []
var quest_requests: Array = []

func _init(p_id: int, p_description: String, p_ongoing: String, p_onfinished: String, 
		p_quest_givers, p_quest_requests, p_prerequisites):
	id = p_id
	description = p_description
	ongoing = p_ongoing
	onfinished = p_onfinished
	
	if p_quest_givers != null:
		quest_givers = p_quest_givers
	
	if p_quest_requests != null:
		quest_requests = p_quest_requests
	
	if p_prerequisites != null:
		prerequisites = p_prerequisites

func add_touch(quest_id: int) -> void:
	touch.append(quest_id)

func create_quest() -> Quest:
	return Quest.new(self)

func _to_string() -> String:
	return "QuestDef(id=%d, description=\"%s\")" % [id, description]
