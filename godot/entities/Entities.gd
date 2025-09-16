class_name Entities
extends Node


func is_ready() -> bool:
	return find_children("*", "Entity").all(
		func(c: Entity) -> bool:
			return c.is_pending())


func execute() -> void:
	if not is_ready():
		return
	for c: Entity in find_children("*", "Entity"):
		c.execute()
