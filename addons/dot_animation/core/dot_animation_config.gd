class_name DotAnimationConfig
extends DotConfig

## Every tunable of GameSpice Animation. A game binds it with DotGameConfigBinder (kind `animation`); `cfg/addon/dot_animation/*.yml`, `DOT_ANIMATION_*` and `--animation-*` layer over these defaults. Ranges are inspector slider limits, not caps.

const ADDON := "dot-animation"

## Master switch: off, a machine stays in its initial state and reports no changes.
@export var enabled: bool = true
## Seconds a transition blends when the graph does not say.
@export_range(0.0, 2.0, 0.01) var blend_time: float = 0.15
## Seconds a trigger waits to be consumed before it is dropped; 0 keeps it until used.
@export_range(0.0, 5.0, 0.05) var trigger_seconds: float = 0.3
## Playback rate for every state; 1 is as authored.
@export_range(0.0, 4.0, 0.05) var speed_scale: float = 1.0
## Largest delta a machine takes in one tick, so a hitch does not skip a whole state; 0 is no limit.
@export_range(0.0, 1.0, 0.01) var max_step: float = 0.1


func env_prefix() -> String:
	return "DOT_ANIMATION_"


func cli_prefix() -> String:
	return "--animation-"


func validate() -> DotResult:
	for pair: Array in [["blend_time", blend_time], ["trigger_seconds", trigger_seconds], ["speed_scale", speed_scale], ["max_step", max_step]]:
		if float(pair[1]) < 0.0:
			return DotResult.fail(DotError.CODE_INVALID, "animation %s %s is negative" % [pair[0], pair[1]])
	return DotResult.success(self)


## Defaults, then `cfg/addon/dot_animation/*.yml` and the game tier, then environment and command line.
static func from_files() -> DotResult:
	var cfg := DotAnimationConfig.new()
	var files := DotAddonConfig.load_dir(ADDON)
	if not files.ok:
		return files
	cfg.apply_dictionary(files.value as Dictionary, "yml")
	return cfg.load_layered()


func describe() -> String:
	return "animation %s blend %.2fs trigger %.2fs speed x%.2f step %.2fs" % ["on" if enabled else "disabled", blend_time, trigger_seconds, speed_scale, max_step]
