extends Node

# Level Signals
signal SHOW_WIN_SCREEN
signal level_switched
signal level_done

# Input Signals
signal undo_timer_continuous_timeout
signal undo_timer_init_timeout

# Player Signals
signal state_changed(direction : Vector2, possessed_creature : Creature)
signal player_move_started #
signal player_move_finished #
signal player_possessed_creature() #
signal player_unpossessed_creature() #

# Creature Signals
signal two_creatures_approached #
signal neighboring_creature_gone #
signal creatures_merged #
#signal creatures_unmerged # für zurückspulen # doch nicht, aber funktion wird bei undo ausgelöst

# Stone Signals
signal stone_reached_target

# Button Signals

# Door Signals
