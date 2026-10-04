# RFG-331 Character HUD completion

This branch continues the merged RFG-337 native HUD and RFG-338 Actor Favorites.
It implements the remaining category workflows from the approved
[RFG-331 specification](https://linear.app/rookframe/issue/RFG-331/character-hud-rework).

Verification records will identify actual behavior exercised and evidence limits.
Temporary GdUnit verification scripts, helper fixtures and runner wiring are
discarded before delivery; they do not expand the retained regression portfolio.

## Shared Favorite controls

Four disposable graphical GdUnit cases passed in 1.074 seconds with stock Godot 4.7.2 Mono. Actual mouse input exercised the authored HUD at desktop 1920 × 1080, tablet 1024 × 768 and phone 844 × 390. The checks covered fixed bar geometry, phone Abilities 2 × 2 at 142 px, initially empty favorites, Show all, immediate current-authority stars preserving a concurrent HP edit, removed-source tombstones with grey launch and enabled removal, Powers Morning header bounds, and an outstanding star reply retaining its initiating Actor through a HUD context change.

The external SDK host services were substituted; the authored UI and System Favorite authority were real. This evidence does not establish whole-workspace layers, published joining, persistence across process reopening, or physical device operation. RFG-344 covers the remaining integration evidence. Temporary suites, helper boundaries and UIDs were removed; development snapshots remain under `/tmp/rfg-331-context`.

After all category adapters were composed, the same four native cases passed again in 1.195 seconds with zero errors, failures, skips or orphan nodes (`category-composition-results.xml`). The removed-source check now filters to the saved Favorite before removal, since the newly implemented intrinsic attacks are also present under Show all. This final run verifies shared control refresh with the real category projections; external host services remain substituted. Temporary code and UIDs were removed again.

## Reviewed public release

[Public v1.0.123](https://github.com/rookframe/rookframe-mork-borg/releases/tag/v1.0.123) is built from source `7d8c873b116afc2ca0709dd5a76065e336cd79ab`, Build ID `50ba3d41-52be-4559-aa88-5ce30fc16613`. Its [HTTPS Manifest](https://github.com/rookframe/rookframe-mork-borg/releases/download/v1.0.123/0404eb56-ef27-4b1a-8385-27e4e3ec907e-1.0.123.json) and archive passed public read-back verification (`release123.json`). It requires SDK Edition 2029 revision 28, supplied by [SDK v0.32.23](https://github.com/rookframe/rookframe-sdk/releases/tag/v0.32.23), and the compatible Actor-task host in [host PR #26](https://github.com/rookframe/rookframe-godot/pull/26). Previous releases remain immutable.

All 304 retained extension cases passed across 25 suites in 32.284 seconds with zero errors, failures, skips, flaky cases or orphan nodes (`retained-results.xml`). Public SDK source admission and prepared-artifact verification passed (`source123.json`, `artifact123.json`). The [review-fix evidence](../rfg-331-review/README.md) additionally records 25 disposable checks and 157 affected regressions; independent Standards and Spec re-review found no outstanding functional findings. Temporary verification source and wiring were removed.

Application diagnostics began after public 1.0.123 publication and uncovered the context, dock-layout and pagination fixes recorded separately. Those failed runs remain diagnostics. Whole-workspace diagnostics continue with public 1.0.124. Final independent empty-store automatic joining, reopening persistence and native layer/input acceptance are pending; source/artifact checks do not substitute for that application evidence.


## Reviewed public 1.0.124 release

[Public v1.0.124](https://github.com/rookframe/rookframe-mork-borg/releases/tag/v1.0.124) is built from source `d74638399917c4848ae15f53f2156e0301c5933f`, Build ID `fa64f9cc-a404-4883-9943-11dac8ad96e9`. Its [HTTPS Manifest](https://github.com/rookframe/rookframe-mork-borg/releases/download/v1.0.124/0404eb56-ef27-4b1a-8385-27e4e3ec907e-1.0.124.json) and archive passed public read-back verification (`release124.json`). Public SDK v0.32.23 remains Edition 2029 revision 28. Runtime UI Kit commit `e2a1e807d73c907bf360aa38a21a55b1773965e2` was acquired normally from its official repository; released SDK defaults and earlier Package releases remain immutable.

All 304 retained extension cases passed across 25 suites in 32.189 seconds with zero errors, failures, skips, flaky cases or orphan nodes (`retained124-results.xml`). Public SDK source admission and prepared-artifact verification passed (`source124.json`, `artifact124.json`). Independent final Standards and Spec source reviews found zero outstanding findings.

The [dock-layout record](../rfg-331-dock-layout/README.md) contains 14 disposable native cases. The [header-width record](../rfg-331-header-width/README.md) contains nine native GdUnit cases with actual mouse and touch input at all three canonical canvases. The public UI Kit lifecycle record contains four native GdUnit cases with 20 assertion checkpoints; earlier standalone counters are diagnostic evidence only. Temporary source, helpers and wiring were discarded, with no new retained profile matrix or Fast Gate expansion.

Public 1.0.124 native run19 failed: Authority one failure in 158.111 seconds; Participant 15 failures in 138.190 seconds, with zero in-case errors and two outside-case GL texture teardown errors. Later Power and Item starts reported earlier actions still active. Cancellation during managed Actor-task destruction is under investigation; no final native acceptance is claimed. Failed native reports and captures are retained in the host RFG-344 diagnostic record.

Public125 supersedes this release; its publication and diagnostic results are
recorded below.


## Reviewed public 1.0.125 release

[Public v1.0.125](https://github.com/rookframe/rookframe-mork-borg/releases/tag/v1.0.125) is built from source `46977f51024bb91847ad90b9f4599b34cefcf8a8`, Build ID `9519f229-5355-4959-a6e2-8757805ed704`. Its [HTTPS Manifest](https://github.com/rookframe/rookframe-mork-borg/releases/download/v1.0.125/0404eb56-ef27-4b1a-8385-27e4e3ec907e-1.0.125.json) and archive passed public read-back verification (`release125.json`). Public SDK v0.32.23 and exact runtime UI Kit `e2a1e807d73c907bf360aa38a21a55b1773965e2` remain unchanged. Earlier releases remain immutable.

All 304 retained cases pass across 25 suites in 32.135 seconds with zero errors, failures, skips, flaky cases or orphan nodes (`retained125-results.xml`). Public SDK source admission and prepared-artifact verification pass with no diagnostics (`source125.json`, `artifact125.json`). Independent Standards and Spec cancellation reviews each report zero findings.

The [cancellation record](../rfg-331-action-cancellation/README.md) verifies the real authored task/controller closure seam with substituted transport timing: 16 disposable cases pass in 4.259 seconds, while the matching original baseline fails 15 cases with 37 assertion failures. All 84 affected retained cases pass in 6.429 seconds. Existing Nodes, signals, authored UI, Authority, gameplay and SDK rules remain in place; one stock RefCounted helper completes pending submissions and cancellation retries after task destruction, then releases. Temporary suites, helpers, UIDs and debug instrumentation were discarded.

The original complete public125 run28 remains red: Authority one case in
140.175 seconds and Participant one case in 119.812 seconds, each with one
failure and zero in-case errors. The later Attacks panel closes during an
incomplete native World update. Two GL texture errors also occur after the
Authority case during engine shutdown. These reports and captures remain
diagnostics, not final acceptance.

The paired [HUD readiness correction](../rfg-331-hud-readiness/README.md) now
preserves confirmed presentation through transient refusals. Its authored UI
proof and the host's authenticated Session proof are scoped separately; the
combined application requires a new immutable public release and a passing
complete native journey. No final native acceptance is claimed for public125.
