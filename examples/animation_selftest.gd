extends Node

## gs-animation's headless suite (res://examples/animation_selftest.tscn).
## Counts sections run to their last line as well as checks, because a script error aborts a section and not the run.

const EXPECTED_SECTIONS := 9
const EXPECTED_CHECKS := 81

var _passed := 0
var _failed := 0
var _sections := 0
var _changes: Array = []


func _ready() -> void:
	print("gs-animation")
	_config()
	_graph()
	_machine()
	_triggers()
	_blend()
	_notifies()
	_aim()
	_foot()
	_locomotion()
	print("")
	_check(_sections == EXPECTED_SECTIONS, "every section ran to its last line (%d of %d)" % [_sections, EXPECTED_SECTIONS])
	_check(_passed + _failed == EXPECTED_CHECKS, "and the suite ran all %d of its checks (%d)" % [EXPECTED_CHECKS, _passed + _failed])
	print("%d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _doc() -> Dictionary:
	return {
		"initial": "idle",
		"states": {
			"idle": {"clip": "idle_loop", "min_time": 0.2},
			"run": {"clip": "run_loop", "speed": 1.5},
			"jump": {"clip": "jump", "loop": false},
			"dead": {"clip": "die", "loop": false},
		},
		"transitions": [
			{"from": "idle", "to": "run", "when": [["speed", ">", 0.5]], "priority": 1, "blend": 0.2},
			{"from": "run", "to": "idle", "when": [["speed", "<=", 0.5]]},
			{"from": "*", "to": "jump", "when": [["jump", "trigger"]], "priority": 2},
			{"from": "jump", "to": "idle", "when": [["grounded", "true"]], "exit_time": 0.3},
			{"from": "*", "to": "dead", "when": [["alive", "false"]], "priority": 9, "interrupt": true},
		],
	}


func _free() -> GSAnimationConfig:
	var c := GSAnimationConfig.new()
	c.max_step = 0.0
	return c


func _machine_of(doc: Dictionary, cfg: GSAnimationConfig = null) -> GSAnimationMachine:
	var r := GSAnimationGraph.from_dictionary(doc)
	var m := GSAnimationMachine.new(r.value as GSAnimationGraph, cfg if cfg else _free())
	m.changed.connect(func(a: StringName, b: StringName) -> void: _changes.append([a, b]))
	return m


func _config() -> void:
	var c := GSAnimationConfig.new()
	_check(c.validate().ok, "defaults validate")
	c.blend_time = -1.0
	_check(not c.validate().ok and c.validate().error.code == GSError.CODE_INVALID, "a negative blend time fails loudly")
	c.blend_time = 0.0
	c.max_step = 0.0
	_check(c.validate().ok, "blend_time 0 and max_step 0 (no limit) are valid")
	var applied := c.apply_dictionary({"blend_time": 0.4, "speed_scale": 2.0, "enabled": false})
	_check(applied.size() == 3 and c.blend_time == 0.4 and c.speed_scale == 2.0 and not c.enabled, "a dictionary layer sets every type", str(applied))
	_check(c.env_prefix() == "GS_ANIMATION_" and c.cli_prefix() == "--animation-", "env and command-line prefixes")
	var r := GSAnimationConfig.from_files()
	_check(r.ok and (r.value as GSAnimationConfig).describe().begins_with("animation"), "from_files returns a config that describes itself")
	_sections += 1


func _graph() -> void:
	var r := GSAnimationGraph.from_dictionary(_doc())
	_check(r.ok, "the sample graph loads")
	var g: GSAnimationGraph = r.value
	_check(g.initial == &"idle" and g.states.size() == 4 and g.transition_count() == 5, "initial, states and transitions are read")
	_check(g.states[&"run"]["speed"] == 1.5 and g.states[&"idle"]["clip"] == &"idle_loop" and g.states[&"jump"]["loop"] == false, "state fields and defaults")
	var from_idle := g.transitions_from(&"idle")
	_check(from_idle.size() == 3 and from_idle[0]["to"] == &"dead" and from_idle[1]["to"] == &"jump" and from_idle[2]["to"] == &"run", "transitions from a state sort by priority, wildcards included")
	var bad := _doc()
	bad["initial"] = "swim"
	_check(not GSAnimationGraph.from_dictionary(bad).ok, "an unknown initial state fails")
	bad = _doc()
	(bad["transitions"] as Array)[0]["to"] = "fly"
	_check(GSAnimationGraph.from_dictionary(bad).error.message.contains("fly"), "a dangling target names the state")
	bad = _doc()
	(bad["transitions"] as Array)[0]["when"] = [["speed", "~", 1]]
	_check(not GSAnimationGraph.from_dictionary(bad).ok, "an unknown operator fails")
	bad = _doc()
	(bad["transitions"] as Array)[0]["when"] = [["speed", ">"]]
	_check(not GSAnimationGraph.from_dictionary(bad).ok, "a comparison without a value fails")
	_check(not GSAnimationGraph.from_dictionary({}).ok and not GSAnimationGraph.from_dictionary({"states": {"a": {}}, "initial": "b"}).ok, "an empty document and a missing initial fail")
	var h := {"param": &"hp", "op": "==", "value": 3}
	_check(GSAnimationGraph.holds(h, {"hp": 3}, {}) and not GSAnimationGraph.holds(h, {"hp": 4}, {}) and not GSAnimationGraph.holds(h, {}, {}), "== holds, and a missing parameter is false")
	_sections += 1


func _machine() -> void:
	_changes.clear()
	var cfg := GSAnimationConfig.new()
	cfg.blend_time = 0.1
	var m := _machine_of(_doc(), cfg)
	_check(m.current == &"idle" and m.blend_weight() == 1.0, "starts in the initial state, no blend")
	m.tick({"speed": 3.0}, 0.1)
	_check(m.current == &"idle", "idle holds for its min_time even when run is wanted")
	m.tick({"speed": 3.0}, 0.15)
	_check(m.current == &"run" and _changes == [[&"idle", &"run"]], "after min_time the machine moves and emits changed")
	var p := m.pose()
	_check(p["clip"] == &"run_loop" and p["from_clip"] == &"idle_loop" and p["weight"] == 0.0 and is_equal_approx(p["speed"], 1.5), "the pose names both clips at the start of a blend")
	m.tick({"speed": 3.0}, 0.1)
	_check(is_equal_approx(m.blend_weight(), 0.5) and m.pose()["from_clip"] == &"idle_loop", "the transition's own blend time (0.2) is used")
	m.tick({"speed": 3.0}, 0.1)
	_check(m.blend_weight() == 1.0 and m.pose()["from_clip"] == &"", "the blend ends")
	m.tick({"speed": 0.0}, 0.01)
	_check(m.current == &"idle" and is_equal_approx(m.pose()["weight"], 0.0), "run to idle takes the machine's default blend")
	m.tick({"speed": 3.0, "alive": false}, 0.01)
	_check(m.current == &"dead", "an interrupt transition ignores min_time and wins on priority")
	m.tick({"speed": 0.0, "alive": true}, 1.0)
	_check(m.current == &"dead", "nothing leaves dead")
	var off := GSAnimationConfig.new()
	off.enabled = false
	var m2 := _machine_of(_doc(), off)
	m2.tick({"speed": 9.0}, 5.0)
	_check(m2.current == &"idle" and m2.time_in_state == 0.0, "a disabled machine stays put")
	var snap := GSAnimationConfig.new()
	snap.blend_time = 0.0
	snap.max_step = 0.0
	var m3 := _machine_of(_doc(), snap)
	m3.tick({"speed": 3.0}, 0.5)
	_check(m3.current == &"run" and m3.blend_weight() == 0.0, "an explicit transition blend wins over blend_time 0")
	m3.tick({"speed": 0.0}, 0.01)
	_check(m3.current == &"idle" and m3.blend_weight() == 1.0, "blend_time 0 snaps where the graph is silent")
	var capped := GSAnimationConfig.new()
	capped.max_step = 0.05
	var m4 := _machine_of(_doc(), capped)
	m4.tick({}, 5.0)
	_check(is_equal_approx(m4.time_in_state, 0.05), "max_step bounds a hitch")
	capped.max_step = 0.0
	m4.tick({}, 5.0)
	_check(is_equal_approx(m4.time_in_state, 5.05), "max_step 0 is no limit")
	_sections += 1


func _triggers() -> void:
	var m := _machine_of(_doc())
	m.tick({}, 0.3)
	m.trigger(&"jump")
	m.tick({"grounded": false}, 0.01)
	_check(m.current == &"jump", "a trigger takes its transition")
	m.tick({"grounded": true}, 0.1)
	_check(m.current == &"jump", "exit_time holds the jump until 0.3s")
	m.tick({"grounded": true}, 0.3)
	_check(m.current == &"idle", "then grounded leaves it")
	m.tick({}, 0.3)
	m.tick({}, 0.3)
	_check(m.current == &"idle", "the trigger was consumed, it does not fire twice")
	var cfg := GSAnimationConfig.new()
	cfg.trigger_seconds = 0.1
	cfg.max_step = 0.0
	var m2 := _machine_of(_doc(), cfg)
	m2.trigger(&"jump")
	m2.tick({}, 0.05)
	_check(m2.current == &"idle", "idle's min_time holds back a trigger transition")
	m2.tick({}, 0.05)
	m2.tick({}, 0.05)
	m2.tick({}, 0.2)
	_check(m2.current == &"idle", "a trigger that waited longer than trigger_seconds is dropped")
	cfg.trigger_seconds = 0.0
	var m3 := _machine_of(_doc(), cfg)
	m3.trigger(&"jump")
	m3.tick({}, 0.05)
	m3.tick({}, 0.05)
	m3.tick({}, 0.05)
	m3.tick({}, 0.05)
	_check(m3.current == &"jump", "trigger_seconds 0 keeps it until used")
	_sections += 1


func _blend() -> void:
	var pts := [[0.0, "idle"], [2.0, "walk"], [6.0, "run"]]
	_check(GSAnimationBlend.check_points(pts).ok and not GSAnimationBlend.check_points([[1.0, "a"], [1.0, "b"]]).ok and not GSAnimationBlend.check_points([]).ok, "blend space validation")
	var w := GSAnimationBlend.blend_1d(pts, 1.0)
	_check(is_equal_approx(w[&"idle"], 0.5) and is_equal_approx(w[&"walk"], 0.5) and w.size() == 2, "halfway between two points")
	w = GSAnimationBlend.blend_1d(pts, 5.0)
	_check(is_equal_approx(w[&"walk"], 0.25) and is_equal_approx(w[&"run"], 0.75), "a point further along")
	_check(GSAnimationBlend.blend_1d(pts, -3.0) == {&"idle": 1.0} and GSAnimationBlend.blend_1d(pts, 99.0) == {&"run": 1.0}, "clamped at both ends")
	_check(is_equal_approx(float(GSAnimationBlend.blend_1d(pts, 2.0).get(&"walk", 0.0)), 1.0), "exactly on a point is that clip")
	_check(GSAnimationBlend.blend_1d([], 1.0).is_empty(), "no points, no weights")
	var l := GSAnimationBlend.layer({&"walk": 1.0}, {&"aim": 1.0}, 0.25)
	_check(is_equal_approx(l[&"walk"], 0.75) and is_equal_approx(l[&"aim"], 0.25), "a layer mixes over the base")
	_check(GSAnimationBlend.layer({&"walk": 1.0}, {&"aim": 1.0}, 0.0) == {&"walk": 1.0} and GSAnimationBlend.layer({&"walk": 1.0}, {&"aim": 1.0}, 7.0) == {&"aim": 1.0}, "layer weight is clamped to 0..1 and zeros are dropped")
	_check(GSAnimationBlend.approach(0.0, 1.0, 2.0, 0.25) == 0.5 and GSAnimationBlend.approach(0.9, 1.0, 2.0, 0.25) == 1.0 and GSAnimationBlend.approach(1.0, 0.0, 2.0, 0.25) == 0.5, "approach moves at speed and never overshoots")
	_sections += 1


func _notifies() -> void:
	var n := GSAnimationNotifies.new()
	_check(n.add(&"run", 0.25, &"step_l").ok and n.add(&"run", 0.75, &"step_r").ok and n.add(&"run", 0.0, &"start").ok, "three notifies pinned")
	_check(not n.add(&"run", 1.5, &"bad").ok and not n.add(&"run", -0.1, &"bad").ok and n.count(&"run") == 3, "out of range times fail loudly")
	_check(n.fire(&"run", 0.1, 0.3) == [&"step_l"], "a step fires what it passes")
	_check(n.fire(&"run", 0.25, 0.5).is_empty() and n.fire(&"run", 0.2, 0.25) == [&"step_l"], "(prev, now]: the end is in, the start is out")
	_check(n.fire(&"run", 0.7, 0.3, true) == [&"start", &"step_l", &"step_r"], "a loop wrap covers the end of the clip and the start of the next pass", str(n.fire(&"run", 0.7, 0.3, true)))
	_check(n.fire(&"walk", 0.0, 1.0).is_empty(), "a clip with no notifies fires nothing")
	_sections += 1


func _check(ok: bool, what: String, extra: String = "") -> void:
	if ok:
		_passed += 1
		print("  ok    ", what)
	else:
		_failed += 1
		print("  FAIL  ", what, "  ", extra)


func _aim() -> void:
	var c := GSAnimationConfig.new()
	var aim := GSAnimationAim.new(c)
	var a := GSAnimationAim.angles_to(Vector3(0, 0, 1), Vector3(1, 0, 1))
	_check(is_equal_approx(a.x, PI / 4.0) and is_zero_approx(a.y), "angles_to gives the yaw of a diagonal look")
	_check(GSAnimationAim.angles_to(Vector3.ZERO, Vector3.ONE) == Vector2.ZERO, "a zero vector gives zero angles")
	_check(GSAnimationAim.angles_to(Vector3(0, 0, 1), Vector3(0, 1, 1)).y > 0.0, "looking up gives positive pitch")
	c.ik_half_life = 0.0
	var r := aim.step(Vector2(PI, 1.5), 0.016)
	_check(is_equal_approx(r.x, deg_to_rad(80.0)) and is_equal_approx(r.y, deg_to_rad(70.0)), "aim is clamped to the config limits")
	c.aim_max_yaw = 0.0
	_check(is_equal_approx(aim.step(Vector2(PI, 0), 0.016).x, PI), "aim_max_yaw 0 means no limit")
	c.ik_half_life = 0.1
	aim.reset()
	var half := aim.step(Vector2(1.0, 0.0), 0.1)
	_check(is_equal_approx(half.x, 0.5), "one half-life covers half the way")
	var out := PackedVector2Array()
	aim.distribute(PackedFloat32Array([1.0, 3.0]), out)
	_check(out.size() == 2 and is_equal_approx(out[1].x, half.x * 0.75), "distribute splits by relative weight")
	aim.distribute(PackedFloat32Array([0.0, 0.0]), out)
	_check(out[0] == Vector2.ZERO, "all-zero weights give nothing rather than NaN")
	c.aim_max_pitch = -1.0
	_check(not c.validate().ok, "a negative aim limit is refused")
	_sections += 1


func _foot() -> void:
	var c := GSAnimationConfig.new()
	c.ik_half_life = 0.0
	var f := GSAnimationFoot.new(c)
	_check(is_equal_approx(f.step(0.0, -0.2, true, 0.016), -0.2), "the foot reaches ground below it")
	_check(is_equal_approx(f.step(0.0, -5.0, true, 0.016), -0.5), "reach is limited by foot_max_reach")
	c.foot_max_reach = 0.0
	_check(is_equal_approx(f.step(0.0, -5.0, true, 0.016), -5.0), "foot_max_reach 0 is unlimited")
	_check(is_zero_approx(f.step(0.0, -5.0, false, 0.016)), "no ground found eases back to the animation")
	_check(is_equal_approx(GSAnimationFoot.hip_drop(-0.1, 0.2), -0.1) and GSAnimationFoot.hip_drop(0.1, 0.2) == 0.0, "hips drop for the lower foot only")
	c.ik_half_life = 0.1
	f.reset()
	_check(is_equal_approx(f.step(0.0, 1.0, true, 0.1), 0.5), "smoothing halves the gap per half-life")
	var ap := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	lib.add_animation(&"idle_loop", Animation.new())
	lib.add_animation(&"run_loop", Animation.new())
	ap.add_animation_library(&"", lib)
	add_child(ap)
	var cfg := GSAnimationConfig.new()
	var g := GSAnimationGraph.from_dictionary(_doc()).value as GSAnimationGraph
	var m := GSAnimationMachine.new(g, cfg)
	var v := GSAnimationPlayerView.new()
	v.setup(ap, m)
	_check(v.drive({"speed": 0.0, "alive": true}, 0.016) == &"idle_loop", "the view plays the initial clip")
	v.drive({"speed": 3.0, "alive": true}, 0.1)
	var got := v.drive({"speed": 3.0, "alive": true}, 0.1)
	_check(got == &"run_loop" and ap.current_animation == "run_loop", "and switches when the machine does")
	ap.free()
	v.free()
	_sections += 1


func _locomotion() -> void:
	var m := GSAnimationLocomotion.new()
	_check(m.validate().ok and m.state() == GSAnimationLocomotion.IDLE, "locomotion starts idle with valid thresholds")
	_check(m.advance({"speed": 1.0}, 0.016) == GSAnimationLocomotion.WALK, "a slow speed is a walk")
	_check(m.advance({"speed": 8.0}, 0.016) == GSAnimationLocomotion.RUN, "a fast one is a run")
	_check(m.advance({"speed": 3.7}, 0.016) == GSAnimationLocomotion.RUN, "between the exit and the enter threshold a run stays a run")
	_check(m.advance({"speed": 3.0}, 0.016) == GSAnimationLocomotion.WALK, "and below the exit threshold it drops to a walk")
	_check(m.advance({"speed": 3.7}, 0.016) == GSAnimationLocomotion.WALK, "the same speed does not re-enter the run: hysteresis, no flicker")
	_check(m.advance({"speed": 0.15}, 0.016) == GSAnimationLocomotion.WALK and m.advance({"speed": 0.05}, 0.016) == GSAnimationLocomotion.IDLE, "a walk holds down to its exit speed, then stands")
	_check(m.advance({"crouched": true, "speed": 2.0}, 0.016) == GSAnimationLocomotion.CROUCH_WALK, "crouching has its own walk")
	var air := {"on_floor": false, "vertical": -5.0}
	var _a := m.advance(air, 0.01)
	_check(m.advance(air, 0.2) == GSAnimationLocomotion.FALL, "off the ground past the grace is a fall")
	_check(m.advance({"alive": false}, 0.016) == GSAnimationLocomotion.DEAD, "dead overrides everything")
	m.run_exit_speed = m.run_speed
	_check(not m.validate().ok, "no gap between the run thresholds fails loudly")
	_sections += 1
