class_name GSAnimationMachine
extends RefCounted

## Runs a [GSAnimationGraph]: one current state, the transition that leaves it, and the blend from the state it left. It produces names and weights; the game or a rig adapter plays the clips, so the same machine drives a player, an NPC or a 2D sheet.

signal changed(from: StringName, to: StringName)

var graph: GSAnimationGraph
var config: GSAnimationConfig
var current: StringName = &""
var previous: StringName = &""
var time_in_state: float = 0.0

var _blend_len: float = 0.0
var _blend_t: float = 1.0
var _triggers: Dictionary = {}


func _init(p_graph: GSAnimationGraph, p_config: GSAnimationConfig) -> void:
	graph = p_graph
	config = p_config
	current = graph.initial


## Asks for every transition waiting on this trigger. It lives until used or `trigger_seconds` pass (0 keeps it).
func trigger(name: StringName) -> void:
	_triggers[name] = 0.0


## Advances by `delta` seconds against the current parameters and returns the current state.
func tick(params: Dictionary, delta: float) -> StringName:
	if not config.enabled:
		return current
	var dt := delta if config.max_step <= 0.0 else minf(delta, config.max_step)
	time_in_state += dt
	_blend_t = 1.0 if _blend_len <= 0.0 else minf(1.0, _blend_t + dt / _blend_len)
	var state: Dictionary = graph.states[current]
	for t: Dictionary in graph.transitions_from(current):
		if not t["interrupt"] and time_in_state < maxf(float(state["min_time"]), float(t["exit_time"])):
			continue
		if _passes(t, params):
			_take(t)
			break
	if config.trigger_seconds > 0.0:
		for name: StringName in _triggers.keys():
			_triggers[name] = float(_triggers[name]) + dt
			if float(_triggers[name]) > config.trigger_seconds:
				_triggers.erase(name)
	return current


func _passes(t: Dictionary, params: Dictionary) -> bool:
	if t["to"] == current:
		return false
	for cond: Dictionary in (t["when"] as Array):
		if not GSAnimationGraph.holds(cond, params, _triggers):
			return false
	return true


func _take(t: Dictionary) -> void:
	for cond: Dictionary in (t["when"] as Array):
		if cond["op"] == "trigger":
			_triggers.erase(cond["param"])
	var from := current
	previous = from
	current = t["to"]
	time_in_state = 0.0
	_blend_len = float(t["blend"]) if float(t["blend"]) >= 0.0 else config.blend_time
	_blend_t = 0.0 if _blend_len > 0.0 else 1.0
	changed.emit(from, current)


## 0 right after a change, 1 once the blend from the previous state is done.
func blend_weight() -> float:
	return _blend_t


## What to play: `{clip, from_clip, weight, speed, loop}`; `from_clip` is empty when no blend is running.
func pose() -> Dictionary:
	var s: Dictionary = graph.states[current]
	var blending := _blend_t < 1.0 and previous != &""
	return {"clip": s["clip"], "from_clip": (graph.states[previous] as Dictionary)["clip"] if blending else &"", "weight": _blend_t, "speed": float(s["speed"]) * config.speed_scale, "loop": s["loop"]}
