class_name QuestRequest
extends RefCounted

var subject_id: int
var request_type: int
var count: int

func _init(p_subject_id: int, p_request_type: int, p_count: int):
	subject_id = p_subject_id
	request_type = p_request_type
	count = p_count

func _to_string() -> String:
	return "QuestRequest(subject_id=%d, request_type=%d, count=%d)" % [subject_id, request_type, count]

func get_hash() -> int:
	return subject_id * 31 + request_type
