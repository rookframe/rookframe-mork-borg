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
