extends Node2D

# Constants for the quest givers
const QUEST_GIVERS = {
	100: {"name": "Village Chief", "quests": [10, 11, 16, 17]},
	101: {"name": "Village Guard", "quests": [12, 16]},
	102: {"name": "Village Hunter", "quests": [13]},
	103: {"name": "Village Healer", "quests": [14, 15]},
	104: {"name": "Village Elder", "quests": [18]}
}

# Constants for quest subjects
const SUBJECTS = {
	105: {"name": "Priest", "type": RequestType.Type.TALK},
	201: {"name": "Wilderness 1", "type": RequestType.Type.VISIT},
	202: {"name": "Wilderness 2", "type": RequestType.Type.VISIT},
	203: {"name": "Wilderness 3", "type": RequestType.Type.VISIT},
	301: {"name": "Wolf", "type": RequestType.Type.KILL},
	401: {"name": "Bandit", "type": RequestType.Type.KILL},
	501: {"name": "Healing Herb", "type": RequestType.Type.GATHER},
	601: {"name": "Alchemy Station", "type": RequestType.Type.USE},
	701: {"name": "Beast Lair", "type": RequestType.Type.VISIT},
	702: {"name": "Alpha", "type": RequestType.Type.KILL},
	801: {"name": "Mountain 1", "type": RequestType.Type.VISIT},
	802: {"name": "Mountain 2", "type": RequestType.Type.VISIT},
	803: {"name": "Yeti", "type": RequestType.Type.KILL},
}

var quest_manager
var player_id: int = 1

# UI references
@onready var status_label = $CanvasLayer/UI/StatusBar/StatusLabel
@onready var active_quests_list = $CanvasLayer/UI/MainContainer/CenterPanel/ActiveQuestsScroll/ActiveQuestsList
@onready var available_quests_list = $CanvasLayer/UI/MainContainer/RightPanel/TabContainer/Available/AvailableQuestsList
@onready var completed_quests_list = $CanvasLayer/UI/MainContainer/RightPanel/TabContainer/Completed/CompletedQuestsList
@onready var quest_givers_container = $CanvasLayer/UI/MainContainer/LeftPanel/QuestGiversContainer
@onready var quest_template = $CanvasLayer/UI/MainContainer/CenterPanel/ActiveQuestsScroll/ActiveQuestsList/QuestTemplate
@onready var quest_giver_template = $CanvasLayer/UI/MainContainer/LeftPanel/QuestGiversContainer/QuestGiverTemplate

# Custom class for quest subjects
class Subject extends QuestSubject:
	var id: int
	var name: String
	var type: int
	
	func _init(p_id: int, p_name: String, p_type: int):
		id = p_id
		name = p_name
		type = p_type
	
	func get_subject_id() -> int:
		return id

func _ready():
	# Connect action buttons
	var actions_container = $CanvasLayer/UI/MainContainer/LeftPanel/ActionsContainer
	for button in actions_container.get_children():
		button.pressed.connect(_on_action_button_pressed.bind(button.name))
	
	# Set up quest system
	quest_manager = QuestManager.new()
	add_child(quest_manager)
	
	# Load quest definitions from JSON
	var loader = QuestJsonLoader.new("res://quests/definitions.json")
	quest_manager.load_defs(loader)
	
	# Set up JSON storage
	var storage = QuestJsonStorage.new("res://save", quest_manager)
	quest_manager.load_progress(storage)
	
	# Connect quest manager signals
	quest_manager.quest_progress_updated.connect(_on_quest_progress_updated)
	quest_manager.quest_finished.connect(_on_quest_finished)
	quest_manager.quest_available.connect(_on_quest_available)
	quest_manager.quest_accepted.connect(_on_quest_accepted)
	
	# Initialize UI
	_create_quest_giver_buttons()
	update_quests_display()
	set_status("Quest system initialized")

func _create_quest_giver_buttons():
	# Clear any existing quest givers first
	for child in quest_givers_container.get_children():
		if child != quest_giver_template:
			child.queue_free()
	
	# Create a button for each quest giver
	for giver_id in QUEST_GIVERS:
		var giver_info = QUEST_GIVERS[giver_id]
		var giver_ui = quest_giver_template.duplicate()
		giver_ui.visible = true
		giver_ui.name = "QuestGiver_" + str(giver_id)
		
		# Configure the UI elements
		var name_label = giver_ui.get_node("NameLabel")
		var talk_button = giver_ui.get_node("TalkButton")
		var status_panel = giver_ui.get_node("StatusPanel")
		
		name_label.text = giver_info.name
		talk_button.pressed.connect(_on_talk_to_quest_giver.bind(giver_id))
		
		# Set initial status color (gray = no quests, yellow = available quest)
		status_panel.self_modulate = Color(0.5, 0.5, 0.5)
		
		quest_givers_container.add_child(giver_ui)
	
	# Update quest giver status indicators
	update_quest_giver_statuses()

func _on_action_button_pressed(button_name: String):
	var subject_id: int = -1
	var subject_name: String = ""
	var subject_type: int = -1
	
	# Determine which subject to interact with based on the button
	match button_name:
		"TalkPriestButton":
			subject_id = 105
		"VisitWild1Button":
			subject_id = 201
		"VisitWild2Button":
			subject_id = 202
		"Wild3Button":
			subject_id = 203
		"KillWolfButton":
			subject_id = 301
		"KillBanditButton":
			subject_id = 401
		"GatherHerbButton":
			subject_id = 501
		"UseAlchemyButton":
			subject_id = 601
		"VisitBeastLairButton":
			subject_id = 701
		"KillAlphaButton":
			subject_id = 702
		"VisitMountain1Button":
			subject_id = 801
		"VisitMountain2Button":
			subject_id = 802
		"KillYetiButton":
			subject_id = 803
	
	if subject_id > 0 and SUBJECTS.has(subject_id):
		var subject_info = SUBJECTS[subject_id]
		subject_name = subject_info.name
		subject_type = subject_info.type
		
		# Create subject and notify quest system
		var subject = Subject.new(subject_id, subject_name, subject_type)
		quest_manager.notify(player_id, subject, subject_type, 1)
		
		set_status("Interacted with " + subject_name)
	else:
		push_error("Invalid subject for action: " + button_name)

func _on_talk_to_quest_giver(giver_id: int):
	var user = quest_manager.get_quest_user(player_id)
	var giver_info = QUEST_GIVERS[giver_id]
	
	# Check if the giver has any available quests for the player
	var available_quest = null
	
	for quest_def in user.available:
		if giver_info.quests.has(quest_def.id):
			available_quest = quest_def
			break
	
	if available_quest:
		# Accept the quest
		var quest = user.accept_quest(available_quest)
		if quest:
			set_status("Accepted quest: " + quest.def.description)
		else:
			set_status("Failed to accept quest from " + giver_info.name)
	else:
		set_status("No available quests from " + giver_info.name)
	
	# Update displays
	update_quests_display()
	update_quest_giver_statuses()

func update_quests_display():
	# Clear existing quest displays
	for list in [active_quests_list, available_quests_list, completed_quests_list]:
		for child in list.get_children():
			if child.name != "QuestTemplate":
				child.queue_free()
	
	var user = quest_manager.get_quest_user(player_id)
	
	# Display active quests
	for quest_id in user.in_progress_quests:
		var quest = user.in_progress_quests[quest_id]
		var quest_ui = quest_template.duplicate()
		quest_ui.visible = true
		quest_ui.name = "ActiveQuest_" + str(quest_id)
		
		var title_label = quest_ui.get_node("MarginContainer/QuestContent/TitleLabel")
		var desc_label = quest_ui.get_node("MarginContainer/QuestContent/DescriptionLabel")
		var progress_container = quest_ui.get_node("MarginContainer/QuestContent/ProgressContainer")
		
		title_label.text = quest.def.description
		desc_label.text = quest.def.ongoing
		
		# Clear existing progress items
		for child in progress_container.get_children():
			if child.name != "ProgressLabel" and child.name != "ProgressBar":
				child.queue_free()
		
		# Create progress bars for each requirement
		var first_req = true
		for qr in quest.def.quest_requests:
			var req_hash = qr.get_hash()
			var current = quest.cnt[req_hash]
			var total = qr.count
			var subject_name = "Unknown"
			
			if SUBJECTS.has(qr.subject_id):
				subject_name = SUBJECTS[qr.subject_id].name
			
			# Only use the template progress elements for the first requirement
			var progress_label
			var progress_bar
			
			if first_req:
				progress_label = progress_container.get_node("ProgressLabel")
				progress_bar = progress_container.get_node("ProgressBar")
				first_req = false
			else:
				progress_label = progress_container.get_node("ProgressLabel").duplicate()
				progress_bar = progress_container.get_node("ProgressBar").duplicate()
				progress_container.add_child(progress_label)
				progress_container.add_child(progress_bar)
			
			# Update progress display
			var req_type_str = ""
			match qr.request_type:
				RequestType.Type.KILL: req_type_str = "Kill"
				RequestType.Type.GATHER: req_type_str = "Gather"
				RequestType.Type.USE: req_type_str = "Use"
				RequestType.Type.VISIT: req_type_str = "Visit"
				RequestType.Type.TALK: req_type_str = "Talk to"
			
			progress_label.text = req_type_str + " " + subject_name + ": " + str(current) + "/" + str(total)
			progress_bar.max_value = total
			progress_bar.value = current
			
		active_quests_list.add_child(quest_ui)
	
	# Display available quests
	for quest_def in user.available:
		var quest_ui = quest_template.duplicate()
		quest_ui.visible = true
		quest_ui.name = "AvailableQuest_" + str(quest_def.id)
		
		var title_label = quest_ui.get_node("MarginContainer/QuestContent/TitleLabel")
		var desc_label = quest_ui.get_node("MarginContainer/QuestContent/DescriptionLabel")
		var progress_container = quest_ui.get_node("MarginContainer/QuestContent/ProgressContainer")
		
		title_label.text = quest_def.description
		desc_label.text = quest_def.ongoing
		
		# Hide progress container for available quests
		progress_container.visible = false
		
		available_quests_list.add_child(quest_ui)
	
	# Display completed quests
	for quest_id in user.finished_quests:
		var quest_def = quest_manager.get_def(quest_id)
		if quest_def:
			var quest_ui = quest_template.duplicate()
			quest_ui.visible = true
			quest_ui.name = "CompletedQuest_" + str(quest_id)
			
			var title_label = quest_ui.get_node("MarginContainer/QuestContent/TitleLabel")
			var desc_label = quest_ui.get_node("MarginContainer/QuestContent/DescriptionLabel")
			var progress_container = quest_ui.get_node("MarginContainer/QuestContent/ProgressContainer")
			
			title_label.text = quest_def.description
			desc_label.text = quest_def.onfinished
			
			# Hide progress container for completed quests
			progress_container.visible = false
			
			completed_quests_list.add_child(quest_ui)

func update_quest_giver_statuses():
	var user = quest_manager.get_quest_user(player_id)
	
	# Check each quest giver
	for giver_id in QUEST_GIVERS:
		var has_available_quest = false
		var giver_node = quest_givers_container.get_node_or_null("QuestGiver_" + str(giver_id))
		
		if giver_node:
			var status_panel = giver_node.get_node("StatusPanel")
			
			# Check if this giver has any quests available to the player
			for quest_def in user.available:
				if QUEST_GIVERS[giver_id].quests.has(quest_def.id):
					has_available_quest = true
					break
			
			# Update status indicator color
			if has_available_quest:
				status_panel.self_modulate = Color(1, 1, 0.2)  # Yellow for available
			else:
				status_panel.self_modulate = Color(0.5, 0.5, 0.5)  # Gray for no quests

func _on_quest_progress_updated(user_id: int, quest_id: int):
	if user_id == player_id:
		update_quests_display()
		set_status("Quest progress updated")

func _on_quest_finished(user_id: int, quest_id: int):
	if user_id == player_id:
		update_quests_display()
		update_quest_giver_statuses()
		
		var quest_def = quest_manager.get_def(quest_id)
		if quest_def:
			set_status("Quest completed: " + quest_def.description)

func _on_quest_available(user_id: int, quest_id: int):
	if user_id == player_id:
		update_quests_display()
		update_quest_giver_statuses()
		
		var quest_def = quest_manager.get_def(quest_id)
		if quest_def:
			set_status("New quest available: " + quest_def.description)

func _on_quest_accepted(user_id: int, quest_id: int):
	if user_id == player_id:
		update_quests_display()
		update_quest_giver_statuses()

func set_status(message: String):
	status_label.text = "Status: " + message
	print(message)
