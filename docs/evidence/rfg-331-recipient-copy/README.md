# Intrinsic Self recipient and favorite-star presentation

Base: `16c0fff61e83b4cace936b20d7a36191f3f5fab3` (published immutable 1.0.126).
Stock Godot 4.7.2 Mono; public SDK 0.32.23 and runtime UI Kit
`e2a1e807d73c907bf360aa38a21a55b1773965e2`. No version, dependency, SDK,
Frame, rule, targeting/authorization or full-sheet behavior changes.

## Verified native defects

Original native public126 run44 uses actual eligible/Primary input and requests
the correct Master of Fate Presence Throw, but the recipient says `No targets`
instead of the captured Actor's name/HP. `special_panel._render` correctly uses
intrinsic Self for `range_feet == 0`; tabletop configuration clears the hidden
Self checkbox, and `_process` then overwrites that copy with a target summary.
The fix adds only `range_feet > 0` to the existing target-polling guard. Existing
WorldChanged handling rereads the captured Actor and renders updated name/HP.

The same run's favorited filled star is content-colored, while the approved
revision-8 `mork.css` specifies pale-gold for `.mb-star[aria-pressed=true]`.
The HUD set only `font_color`; the native theme provides content-colored
`font_pressed_color` and white `font_hover_pressed_color`. The fix overrides
those two Button state colors using the same existing favorite Gold/muted
choice. The unchanged design-system palette and shared theme are untouched.
[Godot Button theme properties](https://docs.godotengine.org/en/stable/classes/class_button.html#theme-properties)
confirm that pressed and hover-pressed states use their own text colors.

Ranked pre-probe star hypotheses were normal-versus-pressed theme fallback,
hover-pressed fallback alone, and stale favorite state. Authored native controls
report `button_pressed=true` and `★` with normal Gold, pressed content and
hover-pressed white in every device profile, verifying both missing state
overrides and excluding stale favorite state. Frame absence was separately
falsified by exact native pixels: angular cuts, border and pointer render;
`hud_frame.gd` remains unchanged.

## Disposable GdUnit4 acceptance

The six-case suite used real authored `special_panel.tscn` and Character HUD,
actual native theme/Button controls and generated SDK facade in SubViewports;
existing guarded SDK boundary substitutes supplied Actors, selected Rooks,
target snapshots and WorldChanged/target notifications. This is source-control
and domain-boundary acceptance, **not** a new public application/native-input or
physical-device claim. Explicit Self selection used the authored checkbox state
and callback; no new Package installation or acquired payload edits occurred.

- Identical original-source baseline: 6 cases, 745 ms, 5 failed cases / 10
  failed assertions, zero errors/skips/flaky/orphans. It catches initial
  zero-range copy overwrite, target/selection overwrite and both wrong pressed
  star colors for desktop/tablet/phone.
- Candidate: 6 cases, 732 ms, zero errors/failures/skips/flaky/orphans.
  Intrinsic Self keeps the initiating Actor despite target/selection changes;
  later complete Actor updates change the displayed name and HP. Captured
  Actor/source Rook continuity remains intact. Ranged Medicine still changes
  No targets → selected public recipient/in-range → explicit Self → target.
  Filled favorite remains Gold in normal, pressed and hover-pressed theme
  states for all three native presentation profiles.
- Existing special-action and special-composition suites: 59 cases, 949 ms,
  zero errors/failures/skips/flaky/orphans. These include meaningful range,
  Authority action, healing, book-recipient and independent sheet choices.
- Public SDK source check: `source_checked`, accepted, zero Diagnostics.
  Prepared exports and actual application runtime admission remain required for
  the next reviewed immutable release; public126 is unchanged.

The first temporary fixture supplied an incomplete target-event dictionary;
that diagnostic produced native errors. A later fixture counted its own event
construction as a target read. Both were corrected at the substituted boundary,
then the exact corrected suite reran against unchanged baseline and candidate.
Only those final comparable reports above control acceptance; earlier logs
remain diagnostic outside the repository.

## Cost and cleanup

The final disposable acceptance costs under one second; affected regressions
also cost under one second. No retained suite/matrix was added. Both temporary
GdUnit scripts, generated UIDs and any helper/snapshot source were deleted before
commit, including task-owned snapshots outside the repository. The final XML,
complete engine runner logs (ANSI colors alone removed) and source admission
remain here. No native errors were filtered or suppressed. Combined application
acceptance waits for the officially published reviewed successor to 1.0.126.
