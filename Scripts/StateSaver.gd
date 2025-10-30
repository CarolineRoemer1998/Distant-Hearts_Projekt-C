extends Node

var saved_states := []

func get_last_state():
	if saved_states.size() > 0:
		var amount_states = saved_states.size()
		return saved_states[amount_states-1]

func remove_last_state():
	if saved_states.size() > 0:
		saved_states.remove_at(saved_states.size()-1)
