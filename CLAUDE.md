# GameSpice Animation

Godot 4.7+ addon for animation: state machines declared as data, blend and layer rules, foot and aim IK targets, event notifies and one rig contract shared by players and NPCs. Part of the GameSpice addon family.

**The distributable is `addons/gs_animation/`.** It requires only gs-core (`addons/gs_core`, a gitignored symlink to `../../gs-core/addons/gs_core`). Never depend on another addon from here.

| Path | What it holds |
| --- | --- |
| `addons/gs_animation/gs_animation_api.gd` | `LEVEL` and `OLDEST`: the API level (1) and the oldest a consumer may target |
| `addons/gs_animation/core/`, `runtime/` | gs_animation_aim.gd, gs_animation_foot.gd, gs_animation_locomotion.gd, runtime/gs_animation_player_view.gd, gs_animation_blend.gd, gs_animation_config.gd, gs_animation_graph.gd, gs_animation_machine.gd, gs_animation_notifies.gd (core is pure logic: no nodes, no I/O) |
| `cfg/addon/gs_animation/animation.yml` | shipped defaults, layered under the game, environment and command line |
| `examples/animation_selftest.gd` | the headless suite; `EXPECTED_SECTIONS` and `EXPECTED_CHECKS` must match what it runs |

## Boundaries

- Not a player: it decides which clip at what weight, an AnimationPlayer or AnimationTree does the playing.
- Not a character, rig or clip library. `GSAnimationLocomotion` is the generic locomotion state with hysteresis (GameSpice Player Char's `GSPlayerAnimState` extends it); the clip names and presets stay in Player Char.
- Not an IK solver: it computes and exposes targets, the skeleton applies them.
- No importer for clips or skeletons.

## Rules

- Every limit is configurable, 0 means unlimited where a limit makes sense, and a bad value fails loudly through `GSResult`.
- Time is passed in (`now`, `delta`); core classes never read a clock.
- Everything here is prefixed `GSAnimation`. No `uid://` paths.
- Prose says GameSpice, never the internal repo prefix.
- Run the suite with `hv`, never bare Godot. Commit with the owner's identity; never tag.
