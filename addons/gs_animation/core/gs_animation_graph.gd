class_name GSAnimationGraph
extends RefCounted

## A state machine declared as data, validated once so a machine never meets a dangling state.
## Shape: `{"initial", "states": {name: {clip, loop, speed, min_time}}, "transitions": [{from, to, when, priority, blend, interrupt}]}`.
## A condition is `[param, op, value]` or `[param, "true"|"false"|"trigger"]`; `from: "*"` matches every state. Clip names are strings the game resolves.

const OPS: PackedStringArray = [">", "<", ">=", "<=", "==", "!=", "true", "false", "trigger"]
const ANY := "*"

var initial: StringName = &""
var states: Dictionary = {}
var _transitions: Array = []


## Builds a graph from a document. Fails loudly, naming the state or transition, on the first problem.
static func from_dictionary(doc: Dictionary) -> GSResult:
	var g := GSAnimationGraph.new()
	var raw_states: Variant = doc.get("states", {})
	if not raw_states is Dictionary or (raw_states as Dictionary).is_empty():
		return GSResult.fail(GSError.CODE_INVALID, "animation graph has no states")
	for key: Variant in (raw_states as Dictionary):
		var s: Dictionary = (raw_states as Dictionary)[key] if (raw_states as Dictionary)[key] is Dictionary else {}
		var name := StringName(str(key))
		var min_time := float(s.get("min_time", 0.0))
		var speed := float(s.get("speed", 1.0))
		if min_time < 0.0 or speed < 0.0:
			return GSResult.fail(GSError.CODE_INVALID, "animation state '%s' has a negative min_time or speed" % name)
		g.states[name] = {"clip": StringName(str(s.get("clip", name))), "loop": bool(s.get("loop", true)), "min_time": min_time, "speed": speed}
	g.initial = StringName(str(doc.get("initial", "")))
	if not g.states.has(g.initial):
		return GSResult.fail(GSError.CODE_INVALID, "animation graph initial state '%s' is not a state" % g.initial)
	var order := 0
	for raw: Variant in (doc.get("transitions", []) as Array):
		var t: Dictionary = raw if raw is Dictionary else {}
		var from := str(t.get("from", ""))
		var to := StringName(str(t.get("to", "")))
		if from != ANY and not g.states.has(StringName(from)):
			return GSResult.fail(GSError.CODE_INVALID, "transition %d starts at unknown state '%s'" % [order, from])
		if not g.states.has(to):
			return GSResult.fail(GSError.CODE_INVALID, "transition %d ends at unknown state '%s'" % [order, to])
		var conds: Array = []
		for c: Variant in (t.get("when", []) as Array):
			var parts: Array = c if c is Array else []
			if parts.size() < 2 or not OPS.has(str(parts[1])):
				return GSResult.fail(GSError.CODE_INVALID, "transition %d has a bad condition %s" % [order, str(c)])
			var op := str(parts[1])
			if parts.size() < 3 and not (op == "true" or op == "false" or op == "trigger"):
				return GSResult.fail(GSError.CODE_INVALID, "transition %d condition '%s %s' needs a value" % [order, parts[0], op])
			conds.append({"param": StringName(str(parts[0])), "op": op, "value": parts[2] if parts.size() > 2 else null})
		g._transitions.append({"from": from, "to": to, "when": conds, "priority": int(t.get("priority", 0)), "blend": float(t.get("blend", -1.0)), "interrupt": bool(t.get("interrupt", false)), "exit_time": float(t.get("exit_time", 0.0)), "order": order})
		order += 1
	return GSResult.success(g)


func transition_count() -> int:
	return _transitions.size()


## Transitions that can leave `state`, highest priority first, then in the order declared.
func transitions_from(state: StringName) -> Array:
	var out: Array = _transitions.filter(func(t: Dictionary) -> bool: return t["from"] == ANY or t["from"] == String(state))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["order"]) < int(b["order"]) if a["priority"] == b["priority"] else int(a["priority"]) > int(b["priority"]))
	return out


## One condition against the parameters. A parameter that is missing makes it false. `triggers` holds the names of live triggers.
static func holds(cond: Dictionary, params: Dictionary, triggers: Dictionary) -> bool:
	var p: StringName = cond["param"]
	var op: String = cond["op"]
	if op == "trigger":
		return triggers.has(p)
	if not params.has(p) and not params.has(String(p)):
		return false
	var v: Variant = params[p] if params.has(p) else params[String(p)]
	match op:
		"true": return bool(v)
		"false": return not bool(v)
		">": return float(v) > float(cond["value"])
		"<": return float(v) < float(cond["value"])
		">=": return float(v) >= float(cond["value"])
		"<=": return float(v) <= float(cond["value"])
		"==": return v == cond["value"] if not (v is float or v is int) else is_equal_approx(float(v), float(cond["value"]))
		"!=": return v != cond["value"] if not (v is float or v is int) else not is_equal_approx(float(v), float(cond["value"]))
	return false
