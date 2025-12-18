extends Node

# Level Signals
@warning_ignore("unused_signal")
signal SHOW_WIN_SCREEN
@warning_ignore("unused_signal")
signal level_switched
@warning_ignore("unused_signal")
signal level_done

@warning_ignore("unused_signal")
signal level_loaded(season: Constants.SEASON)

# Input Signals
@warning_ignore("unused_signal")
signal undo_timer_continuous_timeout
@warning_ignore("unused_signal")
signal undo_timer_init_timeout
@warning_ignore("unused_signal")
signal undo_timer_buffer_timeout

# Player Signals
@warning_ignore("unused_signal")
signal state_changed(direction : Vector2, possessed_creature : Creature)
#signal player_move_started #
@warning_ignore("unused_signal")
signal player_move_finished #
#signal player_possessed_creature() #
#signal player_unpossessed_creature() #

# Creature Signals
#signal two_creatures_approached #
#signal neighboring_creature_gone #
#signal creatures_merged #
#signal creatures_unmerged # für zurückspulen # doch nicht, aber funktion wird bei undo ausgelöst

# Stone Signals
@warning_ignore("unused_signal")
signal stone_reached_target(stone: PushableObject)

# Button Signals

# Door Signals

# Teleporter
@warning_ignore("unused_signal")
signal teleporter_entered(target_pos: Vector2, body : Node2D)
signal teleporter_activated(teleporter: Teleporter)
signal teleporter_deactivated(teleporter: Teleporter)
signal creature_started_teleporting
signal creature_finished_teleporting(creature: Creature)

# Bees & Flowers
signal flower_grows(flower: FlowerSeed, nearest_bee_swarm: BeeSwarm)
#signal bees_near_creature(creature: Creature)
#signal bees_not_near_creature
signal bees_start_flying
signal bees_stop_flying
signal tried_walking_on_bee_area(bees: BeeSwarm)

# Summer
signal set_lily_pad_on_water_tile(lilypad: LilyPad)
signal player_left_lily_pad(pos: Vector2)

# Fall
signal wind_blows(list_of_blown_objects: Dictionary, blow_direction: Vector2, wind_particles: GPUParticles2D)
signal wind_stopped_blowing

signal undo_executed
