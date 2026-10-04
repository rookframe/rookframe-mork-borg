# RFG-331 Powers header native widths

Base: extension delivery `002695e`, public SDK 0.32.23, independently pinned public UI Kit `e2a1e807`. Stock Godot 4.7.2 Mono and publicly acquired GdUnit4 6.2.1. This is a narrow authored-UI correction; release publication and public-Manifest application acceptance belong to the coordinating task.

## Reproduction and cause

The original public-123 application capture `/tmp/rfg-331-context/final-native-layers18/phone-powers.png` shows Show all overlapping Morning. The same issue appears in tablet and desktop captures. The minimized disposable GdUnit loop uses the actual `character_hud.tscn`, generated SDK facade, production readiness/input bindings, and unchanged public `rookframe_theme.tres` on an ordinary ancestor Control. Removing World transport, persistence, entries and asynchronous resource preparation retains the overlap. The boundary supplies an owned Actor/context and records managed-task openings; it does not replace HUD layout, signals or Godot input dispatch.

Before probes, the ranked hypotheses were fixed allocations smaller than native minima, theme-settlement timing, refresh timing, and drawing-only overrun. The settled native rectangles support the first: Show all is 106 pixels on phone and 110 on tablet/desktop, but the horizontal slot was 88. Morning grows from its 72-pixel slot to 76 on tablet/desktop, also overlapping Close. These are real hit rectangles, not only text overflow. A touch/mouse press in the visible right edge of Show all can therefore open Morning instead of toggling Show all.

`header-native-baseline.xml` and `.log` retain the same nine-case suite on the original delivery source: all nine cases fail (59 assertion failures), zero runtime errors, exit 100, in 3.806 seconds. Native error reporting remains enabled and errors are not filtered. Earlier bounds-only minimization also reproduced the exact phone 106-pixel control before the one-variable width probe.

## Correction and scope

The authored `_layout_panel` keeps its existing preferred widths, but measures each native control's `get_combined_minimum_size().x` and reserves the larger width. The title receives the remaining header width. Show all, Morning and Close retain their labels, styling and bindings. Bar geometry, panel widths/heights, anchor/pointer, body, pages and other categories remain unchanged. No theme asset, runtime pin, SDK, application source or release metadata changes.

## Accepted native evidence

`header-native-accepted.xml` and `.log`: **nine cases passed in 3.832 seconds**, zero errors/failures/skips/flaky/orphans. Three cases check settled Show all/Morning/Close horizontal bounds and invariant bar/panel dimensions at 844 × 390 phone, 1024 × 768 tablet and 1920 × 1080 desktop. Six cases send actual `InputEventScreenTouch` and `InputEventMouseButton` through the stock SubViewport, once for each input type/profile. There is no signal-emission input substitute.

The right-edge Show all press toggles only Show all, preserves the panel and opens no task. Morning opens exactly one SDK task with the initiating `hero` Actor and `daily=true`, without an extra Show all toggle. Reopening retains Show all, toggling back updates its category state, and Close opens no task. Screenshots `phone-powers.png`, `tablet-powers.png` and `desktop-powers.png` show the resulting empty Powers header. They are minimized authored-UI captures, not evidence of the full published application journey.

```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --path . \
  --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
  -a res://tests/hud_header_temp.gd -c \
  -rd reports/header-native-accepted -- \
  --capture-root=/tmp/rfg-331-context/header-native-green
```

The disposable suite, boundary helper and generated UIDs were removed after saving evidence. No retained profile/input matrix was added. Trailing whitespace in the generated baseline XML assertion tables was normalized; report counts and messages are unchanged. `source-admission.log` records the installed public SDK's source-admission check after cleanup. Public-Manifest acquisition and the original application journey are verified separately by the delivery task.
