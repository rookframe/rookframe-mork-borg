# Character HUD artwork

The native HUD follows the approved Silkbound Ledger recipe in
`rookframe-godot/docs/product/design-system/hud.css` and the composition and
interaction authority in `reference/character-hud/`, at host source
`72279d3bef4b8ff8e2bd015cbb1cd621ba48c6e1`.

Use the shared UI Kit theme, EB Garamond fonts and linen texture. The persistent
bar has six-pixel ledger rules; transient action panels are plain reading
surfaces. Desktop (1920 × 1080), tablet (1024 × 768) and landscape phone
(844 × 390) use their own authored reference dimensions.

Ability/category outlines retain the authority's `mork-ui.js` path data.
Attacks and Items use its Tabler swords and backpack assets (MIT, Copyright
Paweł Kuna; see the host's vendored icon credits and Tabler license).
The Dice pictogram is the unchanged `reference/dice.svg`: Dice twenty faces
twenty by Delapouite, Game-icons.net, CC BY 3.0. Attribution also ships in
`ui/hud_art/credits.json`. The checkbox SVGs are native presentation primitives.
No old HUD frames or palette implementation remain.

The authority's background and Graveworm portrait are optional external test
inputs, never Package gameplay content. Supply `--evidence-dir` and
`--reference-dir` to the native HUD suite to capture the reference canvases.
