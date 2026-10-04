# Creature sheet review contract

RFG-345 replaces the older compact Creature sheet. The accepted product contract
and approved desktop/tablet/phone monster HTML authorities live in
`rookframe-godot/docs/product/mork-borg-creature-sheet.md` and
`rookframe-godot/docs/product/mockups/monster-sheets/README.md` and `SOURCES.md`. Use that repository's
unchanged Rookframe design system and its vendored asset boundary. Review desktop
at 1920 × 1080, tablet at 1024 × 768 and landscape phone at 844 × 390.

Library and live Actor sheets share the authored Full-viewport composition:
identity, Encounter / Inventory / Appearance, bounded native UI Kit pages,
readable Details and Source. A live sheet reads the current SDK Actor state;
Library starting values never replace saved identity, signed HP, protection,
morale or capabilities. Preserved effective shield reduction and defence penalties
remain recorded protection independently of carried shield loot.

Creature Inventory is independent carried loot. Its overview shows identity,
quantity and kind; Details retains complete recorded rules and facts. Owner
operations are a searchable core catalogue, custom addition, independent field
saves and removal. Creature loot has no Equip, Attack, Cast or Use operation.
Character equipment keeps its existing semantics. Owner/Viewer presentation and
permitted mutations remain separate from complete shared World gameplay data.

Appearance commits portrait choice/reset and preferred-Miniature changes
immediately, independently of the stat-block draft. The host-owned portrait
picker returns normalized image bytes through the public SDK; Reset restores
the authored portrait. The existing full-viewport Miniature browser provides
name/Package search, None, preview, Cancel and Use Miniature. Existing Rooks
keep their Miniature. Owner mutations reread the latest accepted Authority
Actor and freeze legacy effective capabilities on the first appearance write.
GM Library choices persist in Package-owned World data as defaults for future
creation from that entry; creation snapshots the current Authority defaults.
Changing defaults leaves existing Actors and published definitions unchanged.
RFG-349 through RFG-352 supply corrections, HP adjustment/death and Window Dice;
the live adapter exposes explicit signals and opt-in controls for those slices.

Back/Escape restores the Inventory entry and its native focus. Per-Actor local
chapter/page state lasts for the World Application session and resets on restart.
Absent values, removed entries and unavailable content retain readable states.
Actor placement remains the ordinary Actors drag-and-drop operation. Existing
captured targeted tabletop procedures retain their separate task route.

Authored source checks and disposable source fixtures may inspect native layout
and SDK boundaries without application setup. Retain the five focused Library
checks, two severe saved-capability/loot checks and the severe first-appearance
write/stale-data check; remove the obsolete compact
375px composition matrix. These checks do not establish native acquisition,
render/input, network replication or durable application persistence.

The removed Creature title-width localization case also depended on that
compact sheet's `Layout/Tabs/Creature/Preview/Identity/Content/Title` node and
351px content area. It cannot observe the current full-viewport composition.
Retain catalog coverage of complete authored Creature rules and format parity;
review Russian title wrapping with the canonical native views in RFG-354.

RFG-354 owns unified native acceptance after official publication. Install the
exact public HTTPS Manifest normally and acquire World requirements through
normal join. Compare the actual authored sheet at the three canonical viewports,
including long text/loot, English/Russian, readable focus, current Actor state,
Owner/Viewer operations, Appearance return and durable close/reopen/rejoin.
Do not reuse the superseded compact Actor-sheet tour or copied Package stores.
