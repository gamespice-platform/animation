class_name GSAnimationPlayerView
extends Node

## Applies a [GSAnimationMachine] pose to an AnimationPlayer, and goes idle when nothing needs it. It calls `play` only when the clip changes, so a steady state costs one dictionary read per tick and allocates nothing. The player's own blending handles the cross-fade (`custom_blend` is the machine's blend time).

signal clip_changed(clip: StringName)

var player: AnimationPlayer
var machine: GSAnimationMachine
var _clip: StringName = &""


func setup(p_player: AnimationPlayer, p_machine: GSAnimationMachine) -> void:
	player = p_player
	machine = p_machine
	_clip = &""


## Ticks the machine with [param params], then plays its clip if it changed. Returns the clip now playing (empty if the player lacks it, which also pushes an error naming the clip).
func drive(params: Dictionary, delta: float) -> StringName:
	machine.tick(params, delta)
	var clip := machine.clip()
	var speed := machine.speed()
	if clip != _clip:
		if not player.has_animation(clip):
			push_error("GSAnimationPlayerView: AnimationPlayer has no clip '%s'" % clip)  # perf-lint: allow string_build error path only
			return &""
		var blend := machine.config.blend_time
		player.play(clip, blend, speed)
		_clip = clip
		clip_changed.emit(clip)
	player.speed_scale = speed
	return _clip
