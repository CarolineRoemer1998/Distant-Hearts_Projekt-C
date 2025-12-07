extends Node

var saved_states := []

func add(val):
	saved_states.append(val)

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

func get_creature_pos_in_state_from_back(number: int, creature: Creature):
	var creature_pos = Vector2.ZERO
	if saved_states.size() > 0:
		var amount_states = saved_states.size()
		var creature_states_array = saved_states[amount_states-1-number].get(Constants.GROUP_NAME_CREATURE)
		for creature_dict in creature_states_array:
			if creature_dict.get("name") == creature.name:
				creature_pos = creature_dict.get("global_position")
	return creature_pos
		
