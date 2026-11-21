class_name GSAnimationAim
extends RefCounted

## Aim offset as a pure model: turns a look direction into clamped, smoothed yaw and pitch, and spreads it over a chain of bones so a spine bends as a whole. The skeleton applies the numbers; nothing here touches a node.

var yaw: float = 0.0
var pitch: float = 0.0
var _cfg: GSAnimationConfig


func _init(cfg: GSAnimationConfig) -> void:
	_cfg = cfg


## Yaw and pitch in radians of [param dir] relative to a body facing [param forward] (both in the body's own up-is-Y frame). Zero vectors give zero.
static func angles_to(forward: Vector3, dir: Vector3) -> Vector2:
	if forward.is_zero_approx() or dir.is_zero_approx():
		return Vector2.ZERO
	var f := forward.normalized()
	var d := dir.normalized()
	var fy := atan2(f.x, f.z)
	var dy := atan2(d.x, d.z)
	return Vector2(wrapf(dy - fy, -PI, PI), asin(clampf(d.y, -1.0, 1.0)) - asin(clampf(f.y, -1.0, 1.0)))


## Moves toward the aim for [param target] (yaw, pitch radians), clamped to the config limits, and returns the smoothed (yaw, pitch).
func step(target: Vector2, delta: float) -> Vector2:
	var ty := target.x
	var tp := target.y
	if _cfg.aim_max_yaw > 0.0:
		ty = clampf(ty, -deg_to_rad(_cfg.aim_max_yaw), deg_to_rad(_cfg.aim_max_yaw))
	if _cfg.aim_max_pitch > 0.0:
		tp = clampf(tp, -deg_to_rad(_cfg.aim_max_pitch), deg_to_rad(_cfg.aim_max_pitch))
	var k := 1.0
	if _cfg.ik_half_life > 0.0:
		k = 1.0 - pow(0.5, maxf(delta, 0.0) / _cfg.ik_half_life)
	yaw = lerpf(yaw, ty, k)
	pitch = lerpf(pitch, tp, k)
	return Vector2(yaw, pitch)


## Fills [param out] with each bone's share of the current aim; [param weights] are relative (they are normalised), e.g. [1, 1, 2] for two lower spine bones and a chest. Returns out so one array is reused every frame.
func distribute(weights: PackedFloat32Array, out: PackedVector2Array) -> PackedVector2Array:
	out.resize(weights.size())
	var total := 0.0
	for w in weights:
		total += w
	for i in weights.size():
		out[i] = Vector2(yaw, pitch) * (weights[i] / total if total > 0.0 else 0.0)
	return out


func reset() -> void:
	yaw = 0.0
	pitch = 0.0
