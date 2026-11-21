# Aim and foot targets

Both are pure models. The caller supplies directions and ray results; the skeleton applies the output.

- `DotAnimationAim.angles_to(forward, dir)` gives yaw and pitch of a look relative to the body. `step(target, delta)` clamps to `aim_max_yaw` and `aim_max_pitch` and smooths with `ik_half_life`. `distribute(weights, out)` splits the result across a spine chain into a reused array.
- `DotAnimationFoot.step(rest_y, ground_y, hit, delta)` yields the smoothed foot offset, limited by `foot_max_reach`. `hip_drop(left, right)` is how far the hips lower.
- `DotAnimationPlayerView` plays a machine's pose on an AnimationPlayer, only calling `play` when the clip changes.

The locomotion layer in GameSpice Player Char (`DotPlayerAnimState`, hysteresis thresholds) is not moved here yet; it is specific to a character vocabulary.
