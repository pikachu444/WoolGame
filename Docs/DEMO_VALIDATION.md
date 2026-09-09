# Demo input and presentation review

2026-09-08. Independent **static source review**, not a Unity execution or Android test. Reviewed `UnityProject/Assets/CozyRescue/Presentation/WoolLab.cs` against design documents 09A and 13. Runtime corrections remain owned by the main implementer. Line numbers describe the reviewed snapshot and may move.

## Findings requiring correction or runtime confirmation

1. **High — rebuilding the layout loses live geometry state (lines 119–135, 165–176).** On screen size or safe-area change, `BuildPresentation` creates units at the origin and `ResetVisualState` calls `UpdatePresentation(0)` while session time remains nonzero. Remaining units receive zero interpolation, so they stay at the origin while paused and glide back from there after resume. Already consumed units that are still unraveling record the new origin as their capture source. Success time is also reset, replaying the celebration after a resize. Reconstruct exact unit positions and active capture sources for the preserved session time, and preserve celebration timing. Test a safe-area change during transit, unravel, paused play, and completed play.

2. **High — the departure turn occurs before the complete block has left the board (lines 195–196).** Escape coordinates place only the block center outside a boundary. D's three-cell width and C's two-cell height still intersect the board at their turn points; even A/B have insufficient margin for their half-extents. Compute escape using the actual board boundary plus the outgoing footprint half-size and a small margin. Verify the trailing edge is outside before the segment toward the workbench begins. This is distinct from the logic core's complete footprint collision sweep, which is implemented.

3. **High — a reused slot can display two spools, coils, and competing counters (lines 200–212).** Logic frees a slot at the final capture. The finished presentation lasts another .45 s of winding plus .20 s of completion. A new block reaches the same slot after .38 s, leaving up to .27 s of visual overlap. Preserve immediate reservation while retiring or relocating the old spool before the new arrival, and give counters an unambiguous current owner. Reproduce with A selected alone, then D selected immediately when A reaches logical completion.

4. **Medium — continuous drag excursion is not tracked (lines 144–152).** Tap qualification compares only down and up endpoints. A pointer can move more than 8 dp, return, and still count as a tap. Track maximum movement while held and cancel the candidate once the limit is exceeded. Also clear the pending pointer on pause/app background and use the selected pointer consistently. Verify short tap, hold longer than 350 ms, excursion-and-return, and pause during a press.

5. **Medium — stage stepping is missing (line 228).** The UI offers 0.5×/1× but no single-step inspection required by document 13 and the accepted plan. Add a debug-only paused step that advances the same session clock and presentation by a stated interval, then stays paused. Verify it does not affect the automatic-demo scheduling unexpectedly.

6. **Medium — knit connection visibly has a scheduled gap (lines 201–208).** A thread is hidden as soon as a unit reaches .45 s, but the next capture is .48 s after the prior one. This creates a .03 s break between every two captures (approximately two frames at 60 fps), followed by a new source position. Runtime review should check whether this reads as discontinuous. Prefer a short retained/repositioning connection between adjacent sources rather than blinking it off, while preserving the logical capture timing.

7. **Medium — layout rebuild allocates native resources without disposing replaced assets (lines 45–59, 214).** Destroying the old presentation hierarchy does not explicitly destroy dynamically created materials, meshes, or the old generated audio clip. Repeated safe-area/app lifecycle changes can accumulate these resources. Reuse them or track and dispose owned transient resources when rebuilding; verify memory stabilizes through the specified repeated background/resume checks.

8. **Low — control labels can disagree with state after reset/background/rebuild (lines 121–128, 228–235).** Replay after pause leaves the pause button text at “계속”; background pause does not update it; rebuild creates sound/haptic/speed labels using defaults while preserving their underlying booleans/speed. Synchronize all labels from live state in one method.

9. **Low — public presentation selection lacks bounds checking (lines 154–156).** `feedbackAt[id]` is accessed before `Session.TrySelect` rejects an invalid ID. The physical pointer currently supplies valid IDs, but automation or future debug commands can throw. Validate the ID at the presentation boundary; the pure core already rejects it without state mutation.

## Existing pure logic verification

The same eight EditMode test methods have been executed through the optional standalone .NET 9/NUnit 3.13.3 runner: **8 passed, 0 failed**. Covered blocked footprints/invalid IDs, D-C-B-A plus repeated input, color conservation, immediate slot reuse, pause/resume, reset during transit/capture, different delta partitions, and reset from an event callback. This does not verify Unity input, screen composition, animation, device performance, or Android stability.

## Pending actual execution evidence

- Run Unity EditMode tests once the editor is licensed.
- Inspect departures and source/line/spool continuity at 0.5×, including slot reuse.
- Check 16:9, 19.5:9, and 20:9 with safe-area changes, particularly while paused.
- Verify block touch targets meet 48 dp on the target device; the current collider exactly follows visible geometry and this cannot be accepted from code alone.
- Check cute rescue facial expression/paw motion and repeated replay; static source does not establish the visual quality gate.
- Perform Android build and device checks separately; standalone logic success is not an Android acceptance result.
