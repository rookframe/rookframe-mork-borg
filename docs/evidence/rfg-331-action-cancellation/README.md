# RFG-331 task cancellation lifetime

Public 1.0.124 native run 19 was red: after Morning/Power or Item requested a
Throw, native Dice Rail cancellation followed by ordinary managed task closure
could leave an Authority action active and refuse the next action. The bounded
original-prefix native probe 22 reproduced the next Power refusal before any
Scene change. Managed Actor-task release emits `closed`, removes its authored
content and queues it for deletion, which also deletes its action Node children.
The native diagnostics are preserved under
`/tmp/rfg-331-context/final-native-cancel-timing22/` and
`/tmp/rfg-331-context/final-native-public124-19/`.

The disposable GdUnit4 seam verified two causes: parent deletion interrupts the
first start reply's cancellation follow-up; it also interrupts retry of an
acknowledged action's transiently rejected cancellation. The acknowledged,
no-retry control ends successfully. The fix retains only live SDK request/retry
and cancellation in a stock `RefCounted` operation. Coroutine-local references
keep that operation alive until completion or permanent refusal. Its constructor
captures the authored action's stock SceneTree while the action enters the tree;
it does not retain, reparent or search for UI/host Nodes. Existing action Nodes,
UI signals, polling, operation IDs, cancellation checks and 0.5-second stock
SceneTreeTimer retry policy remain in use.

## Disposable authored boundary acceptance

`baseline.xml` / `baseline.log`: 16 cases on public 124 source
`d74638399917c4848ae15f53f2156e0301c5933f`, 15 failed cases / 37 assertion
failures, 4.284 seconds; zero native errors, skips, flaky cases or orphans.
`accepted.xml` / `accepted.log`: the same 16 cases pass in 4.259 seconds with
zero errors, failures, skips, flaky cases or orphans.

The actual Package task scenes/controllers/panels create and parent the action,
receive closure and then undergo ordinary `RemoveChild`/`QueueFree`. The
existing test SDK boundary executes the actual System authorities and generated
SDK facade. Only transport reply timing, Primary activation, eligibility input
and host `closed` delivery are substituted; this is lifecycle/SDK evidence, not
pointer or public multiplayer acceptance. Cases cover:

- Power, Morning, Item and Recovery: held first start replies and cancellation
  rejected once with `rate_limited`; requested Throws end, Actor data is
  unchanged and a subsequent action can start.
- Both Companion melee and defence routes: closing before the initial reply
  ends the routed action without later target mutations.
- Owner access loss, Actor removal and disconnected Session during the held
  first reply: the ordinary Authority cancellation/lifetime rules still end
  the action and pending Throw.
- Permanent Session refusal, directly and after one transient rejection: no
  continued retry or retained request. An accepted held cancellation reply
  keeps the request alive through task deletion and releases it afterward.

WeakRef observations check that operations survive only the pending boundary
and release after their terminal reply. Native errors were not filtered.

Invocation (the disposable suite has been removed):

```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . \
  --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode \
  -a res://tests/action_task_lifetime_temp.gd -c \
  -rd reports/action-task-lifetime-final
```

## Affected checks and delivery scope

`affected.xml` / `affected.log`: 84 existing cases across Melee, Player Defence,
Special actions and Power/Special/Health/Defence composition pass in 6.429
seconds, zero errors/failures/skips/flaky cases/orphans. These include the
existing delayed-reply, coalesced refresh, cancellation/advance retry, full-sheet
Power/Special/Health and separate defence interaction checks.

`source-admission.json`: public SDK 0.32.23 / Edition 2029 revision 28 source
admission accepts with zero diagnostics. This is source admission only; prepared
exports and actual runtime selection remain delivery checks. No SDK, UI Kit pin,
Package version or release metadata changed in this fix. Both disposable suites,
UIDs and tagged diagnostic prints were removed; no retained test matrix was
added. ANSI escapes and trailing whitespace were removed from saved report
text without changing verdicts or messages.

Fresh original public application acceptance remains pending the reviewed new
immutable Package release. These local proofs do not turn the red public 124 run
into a pass and do not replace the final native journey.
