class_name QuestJsonLoader
extends RefCounted

var file_path: String

func _init(p_file_path: String):
	file_path = p_file_path

func load(quests: Dictionary) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open quest definitions file: %s" % file_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("Failed to parse quest JSON: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return
	
	var quest_definitions = json.data
	if not quest_definitions is Array:
		push_error("Quest definitions should be an array")
		return
		
	# First pass: Create all quest definitions
	for definition in quest_definitions:
		if not _validate_quest_definition(definition):
			continue

		var quest_id = int(definition["id"])
		
		var requirements = []
		if definition.has("required") and definition["required"] is Array and not definition["required"].is_empty():
			for req in definition["required"]:
				if req.has("id") and req.has("type") and req.has("count"):
					requirements.append(QuestRequest.new(
						int(req["id"]),
						int(req["type"]),
						int(req["count"])
					))
		else:
			push_warning("No requirements for quest: %d" % quest_id)
			continue
		
		var prerequisites = []
		if definition.has("prerequisites") and definition["prerequisites"] is Array:
			for prereq in definition["prerequisites"]:
				prerequisites.append(int(prereq))		
		var quest_givers = []
		if definition.has("questgivers") and definition["questgivers"] is Array:
			for giver in definition["questgivers"]:
				quest_givers.append(int(giver))
		
		var quest_def = QuestDef.new(
			quest_id,
			definition["description"],
			definition["ongoing"],
			definition["onfinished"],
			quest_givers,
			requirements,
			prerequisites
		)
		
		if quests.has(quest_id):
			push_error("Quest ID collision! Quest %s collides with %s" % [quest_def, quests[quest_id]])
		else:
			quests[quest_id] = quest_def

func _validate_quest_definition(definition: Dictionary) -> bool:
	if not definition.has("id") or not definition.has("description") or \
	   not definition.has("ongoing") or not definition.has("onfinished"):
		push_error("Quest definition missing required fields")
		return false
	return true
