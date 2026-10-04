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

Whole-workspace public acquisition, independent empty-store automatic joining, reopening persistence and native layer/input acceptance are verified separately by RFG-344 against this release. Those checks began after publication; this source/artifact record does not substitute for their application evidence.
