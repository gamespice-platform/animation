class_name GSAnimationNotifies
extends RefCounted

## Events pinned to a clip's normalised time (footstep, hit frame, reload done), fired once as playback passes them, loops included.

const _NONE: Array = []

var _events: Dictionary = {}


## Pins `name` to `time` (0 to 1) of `clip`. Fails loudly outside that range.
func add(clip: StringName, time: float, name: StringName) -> GSResult:
	if time < 0.0 or time > 1.0:
		return GSResult.fail(GSError.CODE_INVALID, "notify '%s' time %.3f is outside 0..1" % [name, time])
	var list: Array = _events.get(clip, [])
	list.append({"t": time, "name": name})
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["t"]) < float(b["t"]))
	_events[clip] = list
	return GSResult.success(list.size())


func count(clip: StringName) -> int:
	return (_events.get(clip, _NONE) as Array).size()


## Names passed when playback goes from `prev` to `now`. A normal step covers (prev, now]; with `wrapped` the clip looped, covering (prev, 1] and [0, now].
func fire(clip: StringName, prev: float, now: float, wrapped: bool = false) -> Array[StringName]:
	var out: Array[StringName] = []
	for e: Dictionary in (_events.get(clip, _NONE) as Array):
		var t := float(e["t"])
		var hit := (t > prev or t <= now) if wrapped else (t > prev and t <= now)
		if hit:
			out.append(e["name"])
	return out
