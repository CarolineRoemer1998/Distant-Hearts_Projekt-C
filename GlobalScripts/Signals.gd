extends Node

# Level Signals
signal SHOW_WIN_SCREEN
signal level_switched
signal level_done

signal level_loaded(season: Constants.SEASON)

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
signal stone_reached_target(stone: PushableObject)

# Button Signals

# Door Signals

# Teleporter
signal teleporter_entered(target_pos: Vector2, body : Node2D)
signal teleporter_activated(teleporter: Teleporter)
signal teleporter_deactivated(teleporter: Teleporter)
signal creature_started_teleporting
signal creature_finished_teleporting

# Bees & Flowers
signal flower_grows(flower: FlowerSeed, nearest_bee_swarm: BeeSwarm)
signal bees_near_creature(creature: Creature)
signal bees_not_near_creature
signal bees_start_flying
signal bees_stop_flying
signal tried_walking_on_bee_area(bees: BeeSwarm)

# Summer
signal set_lily_pad_on_water_tile(lilypad: LilyPad)
signal player_left_lily_pad(pos: Vector2)
