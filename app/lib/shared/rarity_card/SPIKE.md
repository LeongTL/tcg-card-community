# Foil effect spike (Task 3)

Decision date: 2026-10-13. **No frame times were measured.** The owner chose to skip the device test and fix the target instead.

## Decision

- Build the foil styles with **fragment shaders** (the plan's first choice). Task 8 builds `RarityCard` on this.
- The target is **45 fps for a single tilting card and 30 fps for the 9-card grid**. These are acceptance targets, not measured results.
- The existing product rules already cover the failure case: the foil falls back to a plain card on a fetch failure, a low-end device or reduce-motion.

## What this skips

- Nothing was run on a low-end Android phone or an iPhone, so there is no proof that shaders reach 45 fps there.
- The emulator was not used either: it runs on the PC graphics card and would say "smooth" for any shader.

## Revisit when

- The first real-device check of Task 8's `RarityCard` shows the single card under 45 fps or the grid under 30 fps. Then switch the failing styles to layered gradients and blend modes, and update this note.
