# GameSpice Animation

Godot 4.7+ addon for animation: state machines declared as data, blend and layer rules, foot and aim IK targets, event notifies and one rig contract shared by players and NPCs. Part of the GameSpice addon family.

**The distributable is `addons/dot_animation/`.** It requires only dot-core (`addons/dot_core`, a gitignored symlink to `../../dot-core/addons/dot_core`). Never depend on another addon from here.

| Path | What it holds |
| --- | --- |
| `addons/dot_animation/dot_animation_api.gd` | `LEVEL` and `OLDEST`: the API level (1) and the oldest a consumer may target |
| `addons/dot_animation/core/`, `runtime/` | dot_animation_blend.gd, dot_animation_config.gd, dot_animation_graph.gd, dot_animation_machine.gd, dot_animation_notifies.gd (core is pure logic: no nodes, no I/O) |
| `cfg/addon/dot_animation/animation.yml` | shipped defaults, layered under the game, environment and command line |
| `examples/animation_selftest.gd` | the headless suite; `EXPECTED_SECTIONS` and `EXPECTED_CHECKS` must match what it runs |

## Boundaries

- Not a player: it decides which clip at what weight, an AnimationPlayer or AnimationTree does the playing.
- Not a character, rig or clip library; the locomotion layer in GameSpice Player Char stays where it is, and this is the generic engine behind the same idea.
- Not an IK solver: it computes and exposes targets, the skeleton applies them.
- No importer for clips or skeletons.

## Rules

- Every limit is configurable, 0 means unlimited where a limit makes sense, and a bad value fails loudly through `DotResult`.
- Time is passed in (`now`, `delta`); core classes never read a clock.
- Everything here is prefixed `DotAnimation`. No `uid://` paths.
- Prose says GameSpice, never the internal repo prefix.
- Run the suite with `hv`, never bare Godot. Commit with the owner's identity; never tag.
