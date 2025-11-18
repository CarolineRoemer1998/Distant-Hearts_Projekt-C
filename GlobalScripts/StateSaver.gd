extends Node

var saved_states := []

func add(val):
	saved_states.append(val)
	#print(val.get("Player"),"\n")

func get_last_state() -> Dictionary:
	if saved_states.size() > 0:
		var amount_states = saved_states.size()
		return saved_states[amount_states-1]
	return {}

func remove_last_state():
	if saved_states.size() > 0:
		saved_states.remove_at(saved_states.size()-1)

func clear_states():
	saved_states = []
