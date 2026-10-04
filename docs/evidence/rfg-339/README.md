# RFG-339 verification evidence

The authored attack adapter, native docked Control scene and combat authorities
use the generated public Rookframe SDK. Dependencies were installed through
gd-plug from SDK v0.32.23 and the pinned public UI Kit; no Package archive was
installed or copied for this verification.

The disposable SDK-boundary checks exercised the production System intent
handler and native scene. Only the external host storage, Requested Throw
completion and managed-window boundary were substituted using the existing
GdUnit fixtures. The graphical run used stock Godot 4.7.2 Mono with the public
UI Kit theme and actual mouse input on the native Start button.

Verified behavior:

- Each untargeted d20 result (natural 1, would-miss, ordinary hit and natural 20)
  requests a second damage Throw and reports the two raw Roll sequences. It
  commits no recipient, HP, protection or fumble mutation. Later targets and
  selection cannot redirect it, and repeated completion produces one report.
- Exact owned item identities survive rename/reorder, distinguish duplicate
  copies, retain unavailable tombstones, and do not rebind to a new copy.
  Intrinsic Unarmed/Improvised rows expose the same sheet favorite context.
- Unarmed converts the requested physical d4 into d2. Improvised melee/ranged
  binding, chosen object, Coward's Jab exact trait identity and +3 damage use
  the production authority. Native invalid Improvised setup can be corrected.
- Ordinary ranged ammunition spends once. Eurekia spends its independent
  once-per-combat draw once while raw consequences stay manual. Creature
  untargeted attacks use their own flat test and damage, never Character stats.
- The real generated `windows.open_actor_task` adapter hands over the captured
  Actor and exact item. Selection/task replacement cannot replace the open
  native action. Cancellation and lost Owner access stop late interpretation.
- Existing targeted melee, ranged, ammunition and special weapon checks pass.

`attack-ready.png` and `attack-damage.png` capture the native 420-pixel action
surface before the Throw and after a natural 1 while waiting for damage. The
captures are a scene fixture, with a transparent host background. They establish
native action composition and input; they do not claim full application HUD
layering, real Dice Tray rendering, public Manifest acquisition, remote World
joining or physical-device behavior. Those remain integration acceptance.

The source admission log establishes authoring-contract acceptance only; the
SDK checker itself describes runtime selection/export admission as separate.

All disposable test cases and the temporary boundary fixture were removed
before commit. No retained GdUnit tests, runner wiring, dependency source copies
or Package store were added. The permanent test execution cost is unchanged.

Results: focused combat and untargeted boundary checks **33/33**, 2.448 s;
final graphical/native checks **8/8**, 1.360 s. Both runs report zero errors,
failures, skips, flaky cases and orphan nodes. Source admission accepted the
Package with SDK additive revision 28.
