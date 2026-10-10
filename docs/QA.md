# Verification — 2026-10-02

Environment: Windows, Godot 4.7.2.stable.steam.ed1daf0bf. Rendered captures use the Compatibility renderer on NVIDIA RTX 4060 Laptop GPU.

## Automated checks

`tools/test_game.gd`: **315 checks, 0 failures**, exit code 0.

Covered:

- Normal/anomalous passages, both directions, and 0/1/2 bell rings across rooms 1–12.
- Safe first room, final forward exit, and backward exit behavior.
- Initialization of all 26 events and restoration of visibility, materials and transforms between rounds.
- Bell targeting from actual camera direction, bell interactions and per-room counters.
- Actual CharacterBody3D movement using input actions, floor support and side collision.
- Pause freezing movement, transition completion, missing-bell reset, and restart after victory.
- Both chase types survived using actual sprint movement before hitting a passage boundary.
- Sustained eye contact producing failure.
- Full route from room 1 through all required bells to room 13 and victory; room 8 no longer wins.
- Minimal-hint defaults: no startup hint, bell counter, failure explanation, or note rules in the pause menu. The physical note, exit sign and victory title use the configured final room.

The tests run without a rendering window. They verify rules and integration, not subjective horror quality or final character animation.

## Expanded map verification

- tools/test_map.gd: PASS. Actual movement from the far hallway through all four upstairs flights and the carved doorway onto the rooftop, then back down to the return gate. No teleportation within this route.
- tools/test_map.gd -- --annex-only: PASS. Actual movement down to the basement and back, then through the opened classroom door and out again.
- Three-dimensional exit volumes, manual door opening and reset, and missing-door collision restoration are included in the 315 integration checks.
- Actual rendered captures inspected: expanded-stairwell.png, expanded-rooftop.png, expanded-basement.png, expanded-classroom.png, and updated gameplay.png.

## Visual verification

Captured and inspected actual Godot-rendered images:

- `title-screen.png`: Thai menu, controls, sound/sensitivity settings.
- `gameplay.png`: source school model, lighting, first-room signage and HUD.
- `anomaly-poster.png`: changed poster.
- `anomaly-mirror.png`: real planar reflection with ghost body variant.
- `anomaly-door.png`: door removed completely, exposing the classroom.
- `anomaly-window.png`: watcher placed beyond the window plane.
- `anomaly-blackboard.png`: altered writing visible through the classroom door glass.
- `anomaly-blackout.png`: ceiling lighting disabled, flashlight remains usable.

Visual inspection caught and fixed retained source-door glass, an incorrectly positioned outside watcher, an initial non-reflecting mirror, and unlit metallic source materials.

## Environment notes

The restricted execution environment reports failure to read the Windows certificate store and, for a windowed render, failure to create the user shader-cache directory. This game makes no network requests. Rendering and gameplay tests completed despite these platform warnings. No GDScript parse/runtime errors remain in the final test run. Audio shutdown was adjusted to release active playback resources before test exit.

## Remaining production work

- Replace primitive character/ghost/hand models and temporary posters/audio.
- Connect final rig animations for offering, running and punching; current chase collision is functional.
- Replace or detail the classroom and toilet facade. Stairs, rooftop and basement traversal are implemented.
- Playtest difficulty and presentation with people; the 315 checks do not replace this.
- Embed a distributable Thai font, configure exports and test a packaged build before release.

No packaged executable, controller support, persistent save system or final-art claim is included in this delivery.


## Menu and hallway update

Main menu and pause now link to a separate settings page (volume, mouse sensitivity, fullscreen, defaults). Preferences save to user://settings.cfg. Escape returns from settings to its originating menu before resuming play. Pause suspends gameplay time, movement, anomaly updates and active audio.

ForwardExit now sits at the ground-floor hallway end (0, 0.05, -11.7). Required observation props formerly upstairs are in the corridor. The 13-room rules remain unchanged.

Validation: 315 game checks passed. tools/test_menu.gd passed title/settings/pause/resume/return-to-title state checks and actual forward movement triggering room 2 at the hallway end. Actual rendered title-screen.png, pause.png and settings.png were captured; pause and settings layouts were visually inspected. Earlier rooftop traversal results describe the previous exit layout.

## Character integration — 2026-10-04

User-supplied NPC and player models imported. NPC Walk is manually advanced with gameplay; the chase reuses it at higher speed. The supplied static player mesh was given a separate basic skeleton and editable Idle/Walk/Run clips. Player model is visible to the mirror camera; anomaly 9 replaces it with a tinted NPC ghost. Faceless cover follows the NPC head bone.

Actual rendered captures inspected: npc-animated.png, player-animated.png, player-mirror.png, npc-faceless.png. Inspection caught and corrected detached hand weights in the generated rig. The player rig remains a basic procedural weighting pass, not a hand-polished production rig. No source offer/punch clips were supplied.

## Closed routes / first-person view — 2026-10-04

tools/test_view_routes.gd: PASS. Actual input-driven collisions at the stairwell, far end and window boundary; successful progression before the forward barrier. Classroom retained for anomalies. Inspected first-person-forward.png and first-person-feet.png: shoes visible looking down, no head blocking the forward view. Mirror retains the full model. Historical upstairs traversal checks are superseded.
Final regression after the route and camera changes: 315 checks, 0 failures.

## Visible route walls and horror lighting — 2026-10-04

Added concrete wall surfaces and skirting to route blockers; the window boundary has a low wall and transparent closed glazing preserving the watcher sight line. Hidden black exit panels replaced visually by textured end walls. Collision shapes and exit markers unchanged.

Lower ambient lighting, individually authored light pools, shadows and distance fog. Runtime anomaly lighting now scales each authored light instead of resetting all lights to identical strength. Inspected actual horror-hallway.png, horror-no-flashlight.png and horror-wall.png: route and physical signage remain legible; flashlight reveals nearby objects.

## Horror UI — 2026-10-06

MENU AND HALLWAY: PASS (tools/test_menu.gd). Verified title/settings/pause return paths, frozen player and elapsed time during pause, resume, return to title, and actual forward hallway progression. Added regression coverage for preserving the win summary after returning from settings. Inspected rendered title-screen.png, settings.png, pause.png, note-ui.png and win-ui.png at 1440×900. Screenshot capture waits for the menu fade to finish. Godot emitted environment warnings about shader cache access and the Windows certificate store; no script failures occurred.

Paper note UI: rendered and inspected docs/note-ui.png. MENU AND HALLWAY: PASS including note-only visibility, matching configured rule text, E and ESC close paths, and the paper close button signal restoring gameplay.
# Asset/audio integration — 6 October 2026

- `tools/test_game.gd`: 315 checks, 0 failures after prop replacement and animated charm attachment.
- `tools/test_supplied_assets.gd`: PASS in Compatibility rendering and headless validation. Checks all six prop anchors, looping MP3 music, positional MP3 bell, replacement of overlapping chimes, audio pause/resume, event cleanup, charm-to-hand positioning, and physical entry/return through the classroom doorway.
- Inspected rendered images `docs/assets_bell.png`, `assets_bin.png`, `assets_speaker.png`, `assets_extinguisher.png`, `assets_mask.png`, `assets_omamori.png`, and `assets_classroom.png`.
- Music length: 58.93 s, loop enabled. School bell length: 22.27 s, one shot per interaction; a repeat replaces the current chime and still increments the gameplay counter.
- Rendering environment reports unavailable user shader-cache storage and root certificate access. These messages did not prevent rendering or test completion. Audio playback state was checked programmatically; subjective listening/mix validation is not recorded.

# Seven rooms, endings and anomaly 27 — 6 October 2026

- Updated `tools/test_game.gd`: **241 checks, 0 failures** for seven-room progression, all 27 event resets, bell rules, chases and completion.
- `tools/test_seven_endings.gd`: **134 checks, 0 failures**. Covers all seven possible charm rooms and normal E interaction, inventory across rooms, both endings, ending settings round-trip, reset on failure/restart, head-attached mask cleanup, selection/safe-room limits, sprint input/speed lock, continuous walking survival, reverse-walking failure, stationary capture, pause and cleanup.
- Reviewed actual rendered images: `seven_masked_walker.png`, `seven_no_running.png`, `seven_true_ending.png`, `seven_normal_ending.png`.
- Design decisions and editing locations: `SEVEN_ENDINGS_TH.md`. Charm is consumed implicitly at the true ending; a failed run clears it and rerolls its room. Event 27 starts after the bell so the required interaction can be completed before the follower appears.

# Window watcher visibility — 11 October 2026

Event 18 is enabled again. The opaque backing wall has a permanent opening behind one window; its original continuous collision barrier remains. The watcher faces the corridor, uses a standing animation pose, and has a local face light that hides with the actor on reset. `tools/capture_watcher.gd` verifies reset and collision, and captures `watcher_approach.png` and `watcher_no_flashlight.png`. The older 27-image gallery predates this correction.

