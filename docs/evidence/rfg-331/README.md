# RFG-331 Character HUD completion

This branch continues the merged RFG-337 native HUD and RFG-338 Actor Favorites.
It implements the remaining category workflows from the approved
[RFG-331 specification](https://linear.app/rookframe/issue/RFG-331/character-hud-rework).

Verification records identify actual behavior exercised and evidence limits.
Temporary GdUnit verification scripts, helper fixtures and runner wiring are
discarded before delivery; they do not expand the retained regression portfolio.

## Shared Favorite controls

Four disposable graphical GdUnit cases passed in 1.074 seconds with stock Godot 4.7.2 Mono. Actual mouse input exercised the authored HUD at desktop 1920 × 1080, tablet 1024 × 768 and phone 844 × 390. The checks covered fixed bar geometry, phone Abilities 2 × 2 at 142 px, initially empty favorites, Show all, immediate current-authority stars preserving a concurrent HP edit, removed-source tombstones with grey launch and enabled removal, Powers Morning header bounds, and an outstanding star reply retaining its initiating Actor through a HUD context change.

The external SDK host services were substituted; the authored UI and System Favorite authority were real. This evidence does not establish whole-workspace layers, published joining, persistence across process reopening, or physical device operation. RFG-344 covers the remaining integration evidence. Temporary suites, helper boundaries and UIDs were removed; diagnostic results remain under `/tmp/rfg-331-context`.

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


## Reviewed public 1.0.126 release

[Public v1.0.126](https://github.com/rookframe/rookframe-mork-borg/releases/tag/v1.0.126) is built from source `16c0fff61e83b4cace936b20d7a36191f3f5fab3`, Build ID `6ca67b96-487b-47ab-ba14-1ee798c78301`. Its [HTTPS Manifest](https://github.com/rookframe/rookframe-mork-borg/releases/download/v1.0.126/0404eb56-ef27-4b1a-8385-27e4e3ec907e-1.0.126.json) passed public read-back verification; both release assets are published (`release126.json`). Public SDK v0.32.23 and runtime UI Kit `e2a1e807d73c907bf360aa38a21a55b1773965e2` remain unchanged. Previous releases remain immutable.

Independent readiness delta reviews found zero Standards or Spec findings. The [readiness proof](../rfg-331-hud-readiness/README.md) records 13 authored native HUD cases in 1.272 seconds, with 13 affected retained cases in 72.388 seconds; the matching baseline fails four cases with 16 assertion failures. The paired host proof uses actual authenticated Authority and Participant processes and observes stable Session identity during four complete-World replication gaps, genuine access changes, Actor deletion and Session termination. The HUD preserves only its last confirmed state for transient refusals; existing gameplay readiness, access, lifetime and complete-sharing rules remain in place.

All 304 retained cases pass across 25 suites in 32.195 seconds with zero errors, failures, skips, flaky cases or orphans (`readiness-retained-results.xml`). This run used reviewed source `42e698a80a65542673e6bc080d8f65f5e55b7bf6`; release source differs only in evidence and version/URL metadata, with all production scripts, scenes, dependencies and tests identical. Source admission and prepared-artifact verification for actual126 pass with no diagnostics (`source126.json`, `artifact126.json`). These checks do not claim application acceptance. Temporary producer tests and helpers were removed; final native verification snapshots still await cleanup at delivery.

The full public126 native runs 43 and 44 remain failed diagnostics. Run 43 found an incorrect fixture expectation for the hidden intrinsic-Self control; after that fixture correction, run 44 found a real recipient-copy overwrite in the Package UI. Its Authority case took 159.672 seconds and Participant case 139.406 seconds, each with one failure and zero errors; both complete shutdown logs contain zero native, script and GL errors. The approved selected-star color was also visibly mismatched because native Button pressed state colors were not overridden. The [narrow authored-UI fix](../rfg-331-recipient-copy/README.md) addresses both defects; combined acceptance requires a new immutable release. Normal HTTPS installation, independent empty-store joining, reopening and input/layer checks remain pending. No physical-device operation is claimed.


## Reviewed public 1.0.127 release

[Public v1.0.127](https://github.com/rookframe/rookframe-mork-borg/releases/tag/v1.0.127) is built from source `ae521114fda16e33846a1180dcca77f704cada91`, Build ID `0e9c3554-8577-4d17-900c-b57cc636a5f1`. Both assets are published and its [HTTPS Manifest](https://github.com/rookframe/rookframe-mork-borg/releases/download/v1.0.127/0404eb56-ef27-4b1a-8385-27e4e3ec907e-1.0.127.json) passes unauthenticated readback (`release127.json`, `public-manifest127.json`). SDK v0.32.23, Edition 2029 revision 28, runtime UI Kit `e2a1e807d73c907bf360aa38a21a55b1773965e2` and compatible host `7ed2240a212dea924603a9d0c5dd26fe0f6a5ebe` remain unchanged. Earlier releases remain immutable.

The [intrinsic recipient and star correction](../rfg-331-recipient-copy/README.md) preserves captured Actor name/HP for zero-range Features and applies the existing approved Gold/muted favorite colors to native Button pressed and hover-pressed states. Its six disposable authored-control cases pass in 732 ms against a matching original-source baseline with five failed cases/ten assertions; 59 affected cases pass in 949 ms. Independent Standards and Spec reviews each report zero findings. No Frame, rule, authority, SDK, dependency or retained-matrix changes were made.

All 304 retained cases pass across 25 suites in 32.305 seconds at the exact release source, with zero errors/failures/skips/flaky/orphans (`retained127-results.xml`, `retained127-tests.log`). Source and prepared-artifact admission accept with no diagnostics (`source127.json`, `artifact127.json`). Producer temporary source/helpers/UIDs were removed. These proofs are scoped separately from the complete public application journey.

The complete fresh public127 native run45 passes: Authority one case in 161.882 seconds and Participant one case in 141.116 seconds, both with zero errors, failures, skips, flaky cases or orphans. Both processes exit zero, and their complete shutdown logs contain zero native/script errors, exceptions or GL/leak errors. Normal public Manifest installation, independent empty-store automatic acquisition, all category/Tray handoffs, shared Favorites/reopening, complete World sharing and canonical input/layer behavior are observed. The previously failing intrinsic-Self recipient copy and pressed-star color are correct. The passing XML/full logs/state records and selected PNGs are preserved in the coordinated host RFG-344 record.

Final canonical comparison found the Favorite glyph smaller than approved: the authored Button lacked the reference 24px desktop/tablet and 21px phone font-size overrides. The successor immutable public128 release and focused proof below resolve that presentation gap. Run45 remains passing runtime evidence; complete visual acceptance uses the final128 delta review. No physical iPhone or tablet operation is claimed.


## Reviewed public 1.0.128 release

[Public v1.0.128](https://github.com/rookframe/rookframe-mork-borg/releases/tag/v1.0.128), source `0a16aab033f3df87032a6e2c2f12b348b385abd0`, Build ID `fa34d5f3-3b03-46b1-8d50-12ed68ae1110`, publishes both assets and passes unauthenticated [Manifest readback](https://github.com/rookframe/rookframe-mork-borg/releases/download/v1.0.128/0404eb56-ef27-4b1a-8385-27e4e3ec907e-1.0.128.json) (`release128.json`, `public-manifest128.json`). Public SDK v0.32.23, runtime UI Kit `e2a1e807d73c907bf360aa38a21a55b1773965e2` and compatible host `7ed2240a212dea924603a9d0c5dd26fe0f6a5ebe` remain unchanged; earlier releases remain immutable.

The [Favorite glyph correction](../rfg-331-favorite-glyph/README.md) contains exactly three local UI additions: the existing public TaskGlyphButton variation, approved 24px desktop/tablet and 21px phone font size, and entry-dependent pale-gold/muted hover text color. The public glyph style preserves the existing 44×44 minimum and native control/row/panel/bar geometry. One disposable authored native-control case passes in 1.173 seconds against twelve matching baseline assertion failures in 1.192 seconds; six affected UI cases pass in 3.187 seconds. Independent Standards and Spec reviews report zero outstanding findings. All producer temporary suite/helper/UID sources were removed. No shared theme, token, gameplay, authority, SDK, dependency or retained-test changes were made.

At the exact release source, all 304 retained cases pass across 25 suites in 32.309 seconds, with zero errors/failures/skips/flaky/orphans (`retained128-results.xml`, `retained128-tests.log`). Source and prepared-artifact admission accept with zero diagnostics (`source128.json`, `artifact128.json`).

The complete passing public127 run45 supplies unchanged gameplay/install/join/reopen/layer/access proof. Public128 differs in production only by the three verified Favorite styling additions; release metadata and evidence are separate. Focused final public128 run47 passes: Authority one case in 52.314 seconds (suite 52.320), Participant one case in 17.547 seconds (suite 17.554), actual wall time 54.349 seconds. Both have zero errors/failures/skips/flaky/orphans and exit zero; complete shutdown logs contain zero native/script/GL/leak errors or exceptions. Normal fresh HTTPS installation and empty-store automatic acquisition use Build ID `fa34d5f3-3b03-46b1-8d50-12ed68ae1110`, payload SHA-256 `118f379270b2f8b168306981ed8beca16383f31df4d504a6548810f98719e9e1` and Manifest SHA-256 `aee939218a437dab9c0e47d9b3bee811a89c9985b9705b443932fca3dbef58eb`.

Actual controls verify exact fonts 24/24/21, existing TaskGlyphButton, 44×44 minimum, unchanged allocated Favorite bounds 44×64/52/48, all four Gold/muted native text states and real mouse/screen-touch off/on shared membership writes. Canonical Powers and Abilities captures preserve panel/header/bar/Dice composition; root visual review finds no further delta defect. Run46 remains RED diagnostic evidence: exact floating panel equality rejected desktop 460.0001 versus 460 and a tablet subpixel difference. Only the disposable Powers size assertion changed to a bounded ±0.001 pixel per-coordinate tolerance for the same expected integer sizes; no production, workflow, wait or other assertion changed.

Fresh XML, full logs, acquisition/state records, selected captures, source comparison, review and cost records are preserved in coordinated host `docs/implementation/evidence/rfg-344/`. Final verification-source cleanup is recorded there before delivery. No retained E2E matrix, Fast Gate expansion or physical-device claim is added.
