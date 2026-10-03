# RFG-338 verification

Temporary GdUnit4 verification ran against the current Package implementation,
its generated public SDK, and the existing external-host boundary fixtures using
stock Godot 4.7.2 Mono. The final graphical run passed eleven cases in 9.217 seconds,
with zero errors, failures, skips, flaky retries or orphan Nodes. The saved JUnit
report is `temporary-native-results.xml`.

The initial SDK test failed before the implementation and passed afterward.
Subsequent checks verified duplicate owned scroll copies, feature rename/reorder,
removed-source identity and new-copy separation, shared Power exhaustion,
unequip/break/restoration, explicit unstarring, concurrent co-owner field/inventory
and favorite operations, fresh facade/implementation reads, companion attack
identity including migration of legacy companion instances, correction validation,
custom inventory additions, Viewer rejection and durable-commit refusal.

Native graphical checks instantiated the completed full-viewport sheet at
1920 × 1080 desktop, 1024 × 768 tablet and 844 × 390 landscape phone. Mouse events
went through Godot Viewport input, including the embedded desktop/tablet Details
Window. Stars saved immediately, worked inside an unrelated field draft, survived
Cancel and Save, and remained usable after removal and reopening. The three
captures show the unavailable favorite immediately before explicit unstarring.
They were inspected for visible star geometry and readable retained source names.

The host boundary was substituted for these focused checks. This run demonstrates
Package and native Control behavior; actual World disk persistence and complete
network replication continue to use the existing host SDK contract. It does not
claim a new exported/device or public-Manifest-installation journey. No application
Package installation was used during this slice.

Disposable verification code and its generated UID are removed before delivery.
No retained test cases or routine gate wiring are added. The existing creation
boundary fixture is adjusted to exercise the same production sheet operations
through the SDK's System intent/commit callbacks. Passing reports and captures
are evidence only, not an executable regression matrix.
