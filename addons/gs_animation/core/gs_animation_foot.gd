class_name GSAnimationFoot
extends RefCounted

## Foot placement as a pure model: given where the ground was found under a foot (a ray result the caller cast), it produces the IK target height, limited to `foot_max_reach` and smoothed, and how far the hips must drop so both feet reach. No physics here: the game casts, this decides.

var offset: float = 0.0
var _cfg: GSAnimationConfig


func _init(cfg: GSAnimationConfig) -> void:
	_cfg = cfg


## [param rest_y] is the foot's animated height, [param ground_y] where the ray hit; [param hit] false (no ground found) eases back to the animation. Returns the smoothed vertical offset to add to the foot target.
func step(rest_y: float, ground_y: float, hit: bool, delta: float) -> float:
	var want := 0.0
	if hit:
		want = ground_y - rest_y
		if _cfg.foot_max_reach > 0.0:
			want = clampf(want, -_cfg.foot_max_reach, _cfg.foot_max_reach)
	var k := 1.0
	if _cfg.ik_half_life > 0.0:
		k = 1.0 - pow(0.5, maxf(delta, 0.0) / _cfg.ik_half_life)
	offset = lerpf(offset, want, k)
	return offset


## How far the hips drop so the lower of two foot offsets still reaches the ground; 0 when both feet are raised or level.
static func hip_drop(left_offset: float, right_offset: float) -> float:
	return minf(0.0, minf(left_offset, right_offset))


func reset() -> void:
	offset = 0.0
