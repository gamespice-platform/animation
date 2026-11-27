[![GameSpice Animation - GameSpice addon](docs/banner.png)](https://moddingcommunity.com/a/148-gs-animation)

Godot 4.7+ addon for animation: state machines declared as data, blend and layer rules, foot and aim IK targets, event notifies and one rig contract shared by players and NPCs. Part of the GameSpice addon family.

A GameSpice addon, MIT licensed, built with Claude Code and covered by a headless self-test (`res://examples/animation_selftest.tscn`). The games in [Zee's Games](https://zeesgames.com) are built on the GameSpice addons and run on live servers, so the rigs this addon drives are in real play. The assets keep improving through Nightly.

## Install

1. Copy `addons/gs_animation/` and `addons/gs_core/` into your project.
2. Enable the addon in *Project > Project Settings > Plugins*.

It needs only GameSpice Core ([gs_core](https://github.com/gamespice-platform/core)).

## Quick start

```gdscript
var cfg := GSAnimationConfig.from_files().value as GSAnimationConfig
var graph := GSAnimationGraph.from_dictionary({
	"initial": "idle",
	"states": {"idle": {"clip": "idle_loop"}, "run": {"clip": "run_loop", "speed": 1.5}},
	"transitions": [
		{"from": "idle", "to": "run", "when": [["speed", ">", 0.5]], "blend": 0.2},
		{"from": "run", "to": "idle", "when": [["speed", "<=", 0.5]]},
	],
}).value as GSAnimationGraph

var machine := GSAnimationMachine.new(graph, cfg)
machine.changed.connect(func(from, to): print(from, " -> ", to))
machine.trigger(&"jump")                             # one-shot, consumed by the first transition that wants it
machine.tick({"speed": velocity.length()}, delta)
var pose := machine.pose()                           # {clip, from_clip, weight, speed, loop}: feed it to your player

var weights := GSAnimationBlend.blend_1d([[0.0, "idle"], [2.0, "walk"], [6.0, "run"]], speed)
var hits := notifies.fire(&"run", prev_time, now_time, looped)   # footstep and other events
```

## Settings

Every number is a field on `GSAnimationConfig`. The values below are defaults, and the ranges are inspector slider limits, not enforced caps. Set the property from code or a config file (`cfg/addon/gs_animation/animation.yml`, `GS_ANIMATION_*`, `--animation-*`) to go beyond them. A bad value fails loudly in `validate()`.

| Setting | Default | What it does |
| --- | --- | --- |
| `enabled` | true | Master switch: off, a machine stays in its initial state and reports no changes. |
| `blend_time` | 0.15 | Seconds a transition blends when the graph does not say. |
| `trigger_seconds` | 0.3 | Seconds a trigger waits to be consumed before it is dropped; 0 keeps it until used. |
| `speed_scale` | 1.0 | Playback rate for every state; 1 is as authored. |
| `max_step` | 0.1 | Largest delta a machine takes in one tick, so a hitch does not skip a whole state; 0 is no limit. |
| `aim_max_yaw` | 80 | Most a body turns to aim, degrees either side; 0 is no limit. |
| `aim_max_pitch` | 70 | Most a body pitches to aim, degrees; 0 is no limit. |
| `ik_half_life` | 0.05 | Seconds for an aim or foot target to cover half the way; 0 snaps. |
| `foot_max_reach` | 0.5 | Farthest a foot reaches for ground, metres; 0 is no limit. |

## Aim, feet and playing

`GSAnimationAim` clamps and smooths a look into yaw and pitch and spreads it over a bone chain; `GSAnimationFoot` turns a ground hit into a smoothed foot offset and the hip drop; `GSAnimationPlayerView` applies a machine's pose to an AnimationPlayer, calling `play` only when the clip changes. See `docs/ik.md`.

## What it is not

- Not a player: it decides which clip at what weight, an AnimationPlayer or AnimationTree does the playing.
- Not a character, rig or clip library; the locomotion layer in GameSpice Player Char stays where it is, and this is the generic engine behind the same idea.
- Not an IK solver: it computes and exposes targets, the skeleton applies them.
- No importer for clips or skeletons.

## Test

```bash
godot --headless --path . --import
godot --headless --path . res://examples/animation_selftest.tscn
```

The self-test is offline and exits non-zero on any failure.

## Used by

Every game in the collection vendors it:

- [Fatal Contact](https://zeesgames.com/fatal-contact)
- [Airdrift](https://zeesgames.com/airdrift)
- [Playlot](https://zeesgames.com/playlot)
- [Hungario](https://zeesgames.com/hungario)
- [Buses From Hell](https://zeesgames.com/buses-from-hell)
- [Smash Copter](https://zeesgames.com/smash-copter)
- [Zombie Zone](https://zeesgames.com/zombie-zone)
- [Hide n Seek](https://zeesgames.com/hide-n-seek)
- [Prop Hunt](https://zeesgames.com/prop-hunt)
- [Murder Mystery](https://zeesgames.com/murder-mystery)
- [Deathrun](https://zeesgames.com/deathrun)
- [Wipeout](https://zeesgames.com/wipeout)
- [Dangerous Delivery](https://zeesgames.com/dangerous-delivery)
- [Look At Me](https://zeesgames.com/look-at-me)

The whole collection is at [zeesgames.com](https://zeesgames.com).

## Licence

MIT. See [LICENSE](LICENSE). Only the TMC back-end web infrastructure is not open source.
