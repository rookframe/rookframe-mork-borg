# RFG-331 Russian HUD followup

The authored HUD now uses the existing SDK translation service for visible Dice text (КОСТИ / DICE), keeps the canonical Знамения term, and supplies the two missing action feedback headings. Ordinary renamed core Item, Scroll and Weapon names stay literal, including names such as Strength that collide with translation keys. Default Companion attack fragments translate independently of the unchanged Actor name; edited and unknown Creature attack names remain literal.

Rename detection is a local presentation query against the immutable equipment or exact Creature definition/attack identity. Favorite entry and saved record shapes are unchanged. The launched attack uses an ephemeral display copy; Actor names, inventory IDs, custom flags and source data remain untouched. Missing-source Favorites retain their saved display and membership. An empty attack source remains empty.

Native Russian wrapping exposed a tablet title Control extending 5 px above its fixed 52 px row. The existing Label now limits visible lines to the capacity of the authored row, its detail and the existing 3 px VBox gap, using native one-line Label minimum size. It keeps the existing fonts, geometry and wrapping where two lines fit. The existing FullName button appears whenever more lines exist than can be displayed and exposes the complete text through real input. No UI role, theme, token, asset, dependency or gameplay change is included.

## Exact final verification

| Check | Cases | Time | Result |
| --- | ---: | ---: | --- |
| Original source `9deb5834319a4db9efc079d0e287321d3c32ea59` | 1 | 6.765 s | 37 failed assertions; zero engine errors |
| Final authored candidate | 1 | 6.865 s | Zero failures, errors, skips, flaky cases or orphans |
| Affected existing tests | 20 | 4.752 s | Zero failures, errors, skips, flaky cases or orphans |
| Public SDK source admission | — | — | Accepted, zero diagnostics |

The single disposable GdUnit4 case instantiated real authored HUD and attack Controls with the generated public SDK facade and the existing external localization/context/Actor-state boundary. It used native mouse input on desktop and native ScreenTouch input on tablet/phone, checking exactly one authored press per activation. It verified Russian Dice/accessibility, category and header text, Abilities, Powers, phone More, canonical Omens, fixed bar/panel/row bounds, title containment, header nonintersection, and actual FullName activation. Supported ordinary inventory operations reproduced core Item/Scroll/Weapon rename collisions; the case verified raw Player/custom names and unchanged source data. Ordinary star then source removal preserved the saved record, membership and the unavailable literal HUD title. A real default dog Creature and its ordinary renamed attack exercised the Companions HUD and launched task. Additional authored task checks covered an unknown Creature profile caption and the empty jab display.

Desktop is 1920 × 1080, tablet 1024 × 768, and phone 844 × 390. Fractional panel coordinates use a 0.001 px tolerance; fonts, strings and canonical logical bounds retain their exact expectations. English visible DICE and accessibility Dice remain unchanged. These are authored native UI checks with substituted external state, not an installed application, multiplayer or physical-device journey.

The final baseline and candidate use the same assertion/input/workflow scope. The only later driver change snapshots Omens at its successful assertion before pooled row Controls are reused. The incorrect later observation is preserved in `diagnostic-pooled-row-controls.json`; the final `controls.json` records Восстановить знамения. Both disposable source hashes and this observation delta are recorded in `verification.json`.

The affected group includes seven localization, two inventory, two Power composition, four Special composition cases, two existing authored melee-view cases from `ranged_attack.gd`, and three existing Companion row/inventory cases. `affected-command.json` records the exact bounded selection. Existing full 304-case evidence elsewhere belongs to exact public128 source; this followup makes no new full-suite or published129 acceptance claim.

`baseline-results.xml`, `candidate-results.xml` and `affected-results.xml` retain the final JUnit reports. Their adjacent logs contain the complete runner output through process shutdown; only ANSI terminal formatting was stripped for readability. Raw complete logs remain outside the case at `/tmp/rfg-331-context/russian-complete-baseline.log`, `russian-metadata-candidate.log` and `russian-complete-affected.log`. No errors were filtered. `source-admission.json` is the actual final accepted source-only result; prepared export/runtime admission is separate. The ten final production file SHA-256 values, engine/dependency identities, report counts, fixture hashes and cleanup are in `verification.json`.

## Diagnostics, visual review and cost

`diagnostic-baseline3` preserves the initial red case with three fixture anchor warnings (the original generated XML/log are losslessly gzip-compressed, preserving Godot-emitted trailing spaces); `diagnostic-baseline4` preserves its corrected error-free red run. `diagnostic-pre-admission` contains earlier scope/results before the final admitted Control measurement and shared caption changes. Weapon and Companion red reports demonstrate the later ordinary rename/default-caption defects. Alias-compile, overlay and pagination reports are failed intermediate fixture/integration diagnostics, not acceptance. They were corrected before the final green case.

The source checker initially rejected theme-constant and line-height queries and `floori`; final code uses the existing authored 3 px gap, admitted native Control minimum size, and positive integer conversion. The later Companion data rejection was resolved with the existing typed Dictionary local pattern. All rejected checker results are explicitly diagnostic JSON; SDK policy and revision are unchanged.

The seven final PNGs are byte-identical to the set reviewed by the root agent; `capture-comparison.json` records both hashes. `visual-review.md` contains that scoped review and its substituted-boundary limitation. Public dependencies were acquired through ordinary public gd-plug URLs; `dependency-acquisition.log` records acquisition. There was no application Package setup, local store copying or archive import.

The acceptance increment was one disposable case, about 6.9 s, with no retained test or runtime framework expansion. Only affected existing checks were repeated after source changes; no full304 run was added. The disposable suite, optional UID and all temporary source/wiring were removed after preserving evidence. No external GDScript/C# helper snapshot remains for this followup. Release/version metadata and SDK/dependency pins are unchanged.

## Public 1.0.129 delivery addendum

[Public v1.0.129](https://github.com/rookframe/rookframe-mork-borg/releases/tag/v1.0.129) publishes reviewed source `074bc74531fbaf1e823ec0a0b5d8fe1e5051141a`, Build ID `eeb3524f-5ce5-486f-a764-bb273b38cccb`. [Source admission](../rfg-331/source129.json) and [prepared-artifact admission](../rfg-331/artifact129.json) accept with zero diagnostics. [Publication](../rfg-331/release129.json), [build identity](../rfg-331/build129.json) and the [public Manifest record](../rfg-331/public-manifest129.json) preserve exact release provenance.

Unauthenticated [both-asset readback](../rfg-331/public-readback129.json) matches the prepared archive: [HTTPS Manifest](https://github.com/rookframe/rookframe-mork-borg/releases/download/v1.0.129/0404eb56-ef27-4b1a-8385-27e4e3ec907e-1.0.129.json) SHA-256 `4153db2802b3a9dee4e5fd8fe9fa564484a26149f2e196707cd13c9b169423b7`; [Package archive](https://github.com/rookframe/rookframe-mork-borg/releases/download/v1.0.129/0404eb56-ef27-4b1a-8385-27e4e3ec907e-1.0.129.rookpackage) SHA-256 `50d7fce90f756c523bac1ee619279537ee74c7716f1679bfc6e99ea2f23029eb`.

The initial evidence above belongs to `4b33c32bf2bb14e0b9c1c6038555daf530edb314`: one three-profile native case in 6.865 seconds and 20 affected cases in 4.752 seconds. The separate [review-resolution evidence](review-resolution/README.md) belongs to corrective `1237f08c6ebb6ea555eddd3d1452cf819010222d`: one caption-boundary case in 0.799 seconds and 12 affected cases in 0.705 seconds, all passing with zero errors/failures/skips/flaky/orphans. Final [Standards](reviews/russian-standards-final-review.md) and [Spec](reviews/russian-spec-final-review.md) rechecks report zero outstanding findings; the [root visual review](reviews/russian-root-visual-review.md) retains its authored-Control scope.

Unchanged host/domain/theme behavior reuses the separately accepted public127 full and public128 focused proof. Public129 publication/readback and these authored checks do not claim installed-public129 acquisition, public129 joining or physical-device operation. All earlier artifacts and their source scopes remain preserved. No new test run or retained matrix is added by this evidence-only addendum.
