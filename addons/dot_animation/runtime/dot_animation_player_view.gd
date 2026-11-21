class_name DotAnimationPlayerView
extends Node

## Applies a [DotAnimationMachine] pose to an AnimationPlayer, and goes idle when nothing needs it. It calls `play` only when the clip changes, so a steady state costs one dictionary read per tick and allocates nothing. The player's own blending handles the cross-fade (`custom_blend` is the machine's blend time).

signal clip_changed(clip: StringName)

var player: AnimationPlayer
var machine: DotAnimationMachine
var _clip: StringName = &""


func setup(p_player: AnimationPlayer, p_machine: DotAnimationMachine) -> void:
	player = p_player
	machine = p_machine
	_clip = &""


## Ticks the machine with [param params], then plays its clip if it changed. Returns the clip now playing (empty if the player lacks it, which also pushes an error naming the clip).
func drive(params: Dictionary, delta: float) -> StringName:
	machine.tick(params, delta)
	var pose := machine.pose()
	var clip: StringName = pose["clip"]
	if clip != _clip:
		if not player.has_animation(clip):
			push_error("DotAnimationPlayerView: AnimationPlayer has no clip '%s'" % clip)
			return &""
		var blend := machine.config.blend_time
		player.play(clip, blend, float(pose["speed"]))
		_clip = clip
		clip_changed.emit(clip)
	player.speed_scale = float(pose["speed"])
	return _clip
