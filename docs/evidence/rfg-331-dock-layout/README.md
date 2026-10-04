# RFG-331 managed task body sizing

Base: `f4b9782356ffb426483f93762502a22385b9890d`, published MÖRK BORG 1.0.123. This commit leaves versioning and release publication to the coordinating task.

## Verified cause and fix

The public native diagnostic on host `284f763a` opens Power, Item and Recovery through actual HUD pointer input. All three task roots receive a 458 × 0 rectangle and the default vertical `Fill` flag. Their parent TaskSlot VBoxContainer has 458 × 1026 available space and vertical `ExpandFill`. Each authored body ScrollContainer is consequently zero height and clips its populated panel. The panel minimum heights are already positive: 588 for Power, 400 for Item and 186 for Recovery. The real eligibility pointer reaches TaskSlot and produces zero presses. `public123-red.log` and `public123-red-powers.png` preserve this public-Manifest evidence. The top Cancel/Roll buttons are authored task controls, below the host title chrome.

The minimized native check uses the pinned public UI Kit managed surface and the same ScrollContainer → VBox TaskSlot → authored task hierarchy. It substitutes SDK state reads and Authority services only; it does not install a Package, join a World, or claim whole-workspace acceptance. The original Power case has no runtime errors, but fails the body-height, actual press-count and checked-state assertions (`red-native.xml`). The root is 460 × 0, the body is 436 × 0, and its populated VBox panel is 558 pixels high.

Four ranked hypotheses were shown before the probes: missing root allocation; insufficient minimum propagation through the inner ScrollContainer; missing panel minimum; and independent input interception. A one-variable vertical `ExpandFill` probe restores a 460 × 824 task and 436 × 686 body, and real mouse motion/press/release produces exactly one eligibility press. A minimum-only probe still leaves the body too short to expose eligibility and produces zero presses. Thus the existing panel minima and scroll ownership work; changing the root's vertical size flag is sufficient.

The production fix adds `size_flags_vertical = 3` to PowerTask, ItemTask, RecoveryTask and TabletopAttack. The last scene also hosts Companion attacks. No controller, inner panel, fullscreen sheet, engine or SDK capability changes. No hardcoded content height or custom minimum is added.

## Verification

Stock Godot 4.7.2 Mono, public SDK v0.32.23 and GdUnit4 6.2.1, with public dependencies acquired through gd-plug.

`green-native.xml` and `green-native.log`: 14 disposable native cases passed, zero errors/failures/skips/flaky/orphans, 2.842 seconds. They open the actual authored task controllers with captured Actor/task data and cover Power, Morning, Item, Feature, Recovery, Attack and Companion at 900- and 390-pixel container heights. Every route has a positive body and populated panel minimum. Native mouse-wheel press/release reveals clipped controls at compact height; native motion/press/release then produces exactly one press and updates the checkbox or choice. Morning's actual primary-button input creates its Requested Throw through the substituted service boundary. These compact-height checks are not a phone/tablet profile or physical-device claim. An initial wheel fixture omitted release and correctly produced no clicks after scrolling; correcting only that input sequence made all cases pass.

The fast command was:

```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --path . --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/dock_layout_disposable.gd -c -rd reports/dock-wheel-release
```

`affected.xml` and `affected.log`: 10 retained Power, Special, Health and Defence composition cases passed, zero errors/failures/skips/flaky/orphans, 3.812 seconds. The coordinating task owns the final full retained suite and original public application rerun after publishing the superseding release.

`source-check.json`: the pinned official SDK source checker accepts the complete Package with no diagnostics. This is source admission, not prepared-export or application runtime acceptance.

All disposable source, UIDs and instrumentation were removed before committing. No retained test matrix was added. Public 1.0.123 remains immutable; the coordinating task publishes a new release for the original public application verification.
