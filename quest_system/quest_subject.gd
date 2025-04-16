class_name QuestSubject
extends RefCounted

func get_subject_id() -> int:
	push_error("QuestSubject.get_subject_id() must be implemented by subclasses")
	return -1
