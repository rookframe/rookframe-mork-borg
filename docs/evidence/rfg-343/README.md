# RFG-343 verification evidence

The companion adapter projects stable Character favorites for actual owned
Creature Actors and attacks. Launch binds the existing native tabletop task to
that Creature through the generated public SDK. The companion intent chooses
the existing melee or defence workflow on Authority; it never substitutes the
Character's abilities or an unrelated selected Rook.

Dependencies were installed through gd-plug from public SDK v0.32.23 and the
pinned UI Kit. No Package archive or Package store was installed or copied.
Disposable GdUnit checks used existing SDK-boundary fixtures, substituting the
external host storage, managed-window delivery and Requested Throw completion.
Production game rules, adapter, task scene and defence controls were exercised.
The graphical run used stock Godot 4.7.2 Mono, public UI Kit theme, and actual
mouse input on native launch/defence controls.

Verified behavior:

- Exact companion Actor/item identities distinguish duplicate profile copies,
  survive rename/reorder, and retain removable unavailable favorites after
  unequip/removal/access loss. New entries are unfavorited. Descriptive-only
  companions produce no invented attack.
- Untargeted natural 1, would-miss, ordinary hit and natural 20 each request
  damage. The companion uses its own flat test and damage, with no recipient,
  HP, protection or fumble mutations. Later targets/selection do not redirect
  it. Revoked source ownership stops late interpretation.
- Supplied targets retain existing range, protection/damage and defender rules.
  Exact inventory identity prevents a duplicate profile ID from rebinding the
  action to another weapon copy.
- The native HUD adapter opens the actual Creature Actor and exact item. An
  unrelated selected Rook is not substituted; selection and attempted task
  replacement preserve the open action. Explicit closure cancels its Throw.
- A closed retained task reopens for the same Character weapon and companion.
  Two consecutive openings of each were launched with real mouse input and
  explicitly cancelled. Live-action replacement remains guarded.
- A self-defender receives the existing native defence controls. A remote
  pending defence inbox opens the existing Actor window, whose visible Roll
  defence control requests the defending Player's Throw. Ordinary Character
  inspection continues to use the completed full-viewport sheet.

Results: **62/62** cases in the graphical/native and existing melee/defence/
companion suites passed in **9.555 s**. The final **7/7** disposable graphical
cases, including same-Actor reopening, passed in **10.916 s**. Both runs have
zero errors, failures, skips, flaky cases and orphan nodes. Source admission
accepted SDK additive revision 28.

`companion-damage.png` shows the original Creature's flat test and d6 while
waiting for unconditional damage after a natural 1. `remote-defence.png` shows
the actual existing native defender window reached from its inbox. Both are
420-pixel scene fixtures with transparent host backgrounds. They establish
native composition and input at the SDK seam; they do not claim real host HUD
layering, Dice Tray rendering, prepared exports/runtime admission, remote
network replication, public Manifest joining or physical-device behavior.
Those remain integration acceptance.

All temporary test cases, boundary fixture and their UID files were removed
before commit. No permanent GdUnit coverage, runner wiring, dependency source
copies or Package store were added; retained test execution cost is unchanged.
