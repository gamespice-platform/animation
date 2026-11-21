class_name GSAnimationBlend
extends RefCounted

## Blend and layer rules as pure functions over clip weights, so the same numbers drive an AnimationTree, a 2D sheet or a test.


## 1D blend space. `points` is `[[x, clip], ...]` sorted by x; returns clip to weight, summing to 1, clamped at the ends. Equal x values are a bug and fail through [method check_points].
static func blend_1d(points: Array, value: float) -> Dictionary:
	if points.is_empty():
		return {}
	if value <= float((points[0] as Array)[0]):
		return {StringName(str((points[0] as Array)[1])): 1.0}
	var last: Array = points[points.size() - 1]
	if value >= float(last[0]):
		return {StringName(str(last[1])): 1.0}
	for i in points.size() - 1:
		var a: Array = points[i]
		var b: Array = points[i + 1]
		if value >= float(a[0]) and value <= float(b[0]):
			var t := (value - float(a[0])) / (float(b[0]) - float(a[0]))
			var out: Dictionary = {}
			out[StringName(str(a[1]))] = 1.0 - t
			out[StringName(str(b[1]))] = float(out.get(StringName(str(b[1])), 0.0)) + t
			return out
	return {}


## Whether a blend space is well formed: at least one point, strictly increasing x.
static func check_points(points: Array) -> GSResult:
	if points.is_empty():
		return GSResult.fail(GSError.CODE_INVALID, "blend space has no points")
	for i in points.size() - 1:
		if float((points[i + 1] as Array)[0]) <= float((points[i] as Array)[0]):
			return GSResult.fail(GSError.CODE_INVALID, "blend space points must increase in x (point %d)" % (i + 1))
	return GSResult.success(points.size())


## Lays an upper layer over a base: `weight` 0 is the base, 1 is the layer; both are clip to weight maps summing to 1.
static func layer(base: Dictionary, upper: Dictionary, weight: float) -> Dictionary:
	var w := clampf(weight, 0.0, 1.0)
	var out: Dictionary = {}
	for clip: Variant in base:
		out[clip] = float(base[clip]) * (1.0 - w)
	for clip: Variant in upper:
		out[clip] = float(out.get(clip, 0.0)) + float(upper[clip]) * w
	for clip: Variant in out.keys():
		if float(out[clip]) <= 0.0:
			out.erase(clip)
	return out


## Moves `current` toward `target` at `speed` per second without overshooting; the smoothing every parameter wants before it reaches a blend.
static func approach(current: float, target: float, speed: float, delta: float) -> float:
	var step := speed * delta
	return target if absf(target - current) <= step else current + signf(target - current) * step
