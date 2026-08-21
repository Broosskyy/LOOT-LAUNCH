# Phase 17B — Production Preview Free-Roam Inspection

**Date:** 2026-08-21  
**Scene:** `res://scenes/preview/production_assets_preview_v17b.tscn`  
**Script:** `res://scripts/preview/production_assets_preview_v17b.gd`

Preview-only inspection controller for the active **Floating Island production asset**. No gameplay systems are modified.

---

## Joystick component

Reuses the existing Loot Launch analog stick via script preload:

`VirtualJoystickScript = preload("res://scripts/ui/virtual_joystick.gd")`

(Godot 4.7 exposes a native `VirtualJoystick` symbol — the preview avoids shadowing it by using a uniquely named preload.)

- No gameplay dependencies (standalone `Control` + `vector_changed` signal)
- Portrait size in preview: **560 × 475 px**, lower-left of the move zone
- Same dead-zone / recenter behavior as main game HUD

---

## Mobile controls

| Zone | Input | Action |
|------|-------|--------|
| **Left 50 % screen** (`MoveZone`) | Virtual joystick | Forward / back / strafe relative to camera |
| **Right 50 % screen** (`LookZone`) | Finger drag | Yaw (horizontal) + pitch (vertical, clamped ±85°) |
| **Multi-touch** | Separate touch indices | Left thumb moves while right thumb looks |
| **Pinch** | `InputEventMagnifyGesture` | FOV zoom (24°–78°) |
| **Toolbar** | RESET / OVERVIEW / UI / + / − | See below |

Movement is a **fly camera** — no gravity, no player collision, no island collision blocking.

---

## Multi-touch concept

Two independent `Control` regions on `CanvasLayer` (`InspectionUI`, layer 10):

1. **MoveZone** hosts `VirtualJoystick`, which tracks one pointer (`active_pointer`) for the left side.
2. **LookZone** tracks its own `_look_pointer` for screen touch / drag on the right side.

Godot routes each touch to the control under the finger, so joystick and look can run simultaneously without sharing pointer state.

---

## Desktop fallback

| Input | Action |
|-------|--------|
| **WASD** | Planar move (camera-relative) |
| **Q / E** | Down / up |
| **Mouse drag (right zone)** | Look |
| **Mouse wheel** | Move speed (3–42 units/s) |
| **1** | Overview / re-frame island |

Mobile controls remain primary; desktop inputs are additive.

---

## Start camera

On load, after production LOD meshes are ready:

1. Merge **world-space** mesh AABBs (`global_transform * local_aabb`) for visible LOD geometry.
2. Frame the island in a **3/4 elevated view** outside the mesh (`CAMERA_PADDING`, `VIEW_DIRECTION`).
3. Expand distance until the camera position is outside the bounds.
4. Store framing position / yaw / pitch / FOV for **RESET**.

Only after framing completes is `_navigation_ready` set and free-roam enabled.

---

## Reset / Overview / UI

| Button | Behavior |
|--------|----------|
| **RESET** | Restore stored framing transform (position, yaw, pitch, FOV) |
| **OVERVIEW** | Recompute world bounds and re-apply automatic framing |
| **UI** | Toggle debug marker + reference floor visibility |
| **+ / −** | Decrease / increase camera FOV |
| **Pinch** | FOV zoom on supported devices |

---

## Changed files

| File | Change |
|------|--------|
| `scripts/preview/production_assets_preview_v17b.gd` | World-space framing + fly camera + touch/desktop input |
| `scenes/preview/production_assets_preview_v17b.tscn` | Added `InspectionUI` `CanvasLayer` |
| `docs/PHASE_17B_PREVIEW_FREE_ROAM.md` | This document |

---

## Open in Godot

```
scenes/preview/production_assets_preview_v17b.tscn
```

Related import hotfix: `docs/PHASE_17B1_GODOT_IMPORT_HOTFIX.md`
