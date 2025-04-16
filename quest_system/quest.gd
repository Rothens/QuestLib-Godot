class_name Quest
extends RefCounted

var def: QuestDef
var cnt: Dictionary = {}

func _init(p_def: QuestDef):
	def = p_def
	for qr in def.quest_requests:
		cnt[qr.get_hash()] = 0

func set_request(request_hash: int, amount: int) -> void:
	if cnt.has(request_hash):
		cnt[request_hash] = amount
	else:
		push_error("hash=%d not found" % request_hash)

func is_related(subject: QuestSubject, req_type: int) -> bool:
	for qr in def.quest_requests:
		if qr.subject_id == subject.get_subject_id() and qr.request_type == req_type:
			return true
	return false

func notify(subject: QuestSubject, req_type: int, amount: int) -> bool:
	var ret = true
	for qr in def.quest_requests:
		var hash = qr.get_hash()
		var c = cnt[hash]
		
		if qr.subject_id == subject.get_subject_id() and qr.request_type == req_type:
			c += amount
			cnt[hash] = c
			
		if c < qr.count:
			ret = false
	
	return ret
