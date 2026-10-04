# Creature sheet review contract

RFG-345 replaces the older compact Creature sheet. The accepted product contract
and approved desktop/tablet/phone monster HTML authorities live in
`rookframe-godot/docs/product/mork-borg-creature-sheet.md` and
`rookframe-godot/docs/product/mockups/tabletop-shell-*/`. Use that repository's
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

Appearance preserves immediate SDK preferred-Miniature choice and clearing,
using the existing full-viewport browser. Existing Rooks keep their Miniature.
Portrait choice/reset and expanded World Library defaults belong to RFG-353.
Edit sheet retains one shared changed-fields draft for core values, explicit
attacks, structured rules and supported printed formulas. Its core editors open
in the bounded workspace reader while identity, substantial portrait and core
context stay visible, including on phone. Core values is accessible across
chapters; Back retains the draft and Cancel/Escape rereads accepted values.
Untouched fields refresh while native editors keep typed text and focus. Stable
Actor-local correction identities protect replaced entries and printed Rolls.
Save submits semantic field choices for Authority to merge into its latest
Actor, preserving independent accepted loot, Appearance and additional prose.
Known old rule aggregates track their structured edits; independent additional
rules remain readable and editable. Gameplay roll initiation is inactive while
editing. Only two severe-risk correction checks are retained.

RFG-350 through RFG-352 supply HP adjustment/death and Window Dice; the live
adapter exposes editing_sheet(), draft_value() and change_draft() for those
follow-ups alongside accepted current_data() and explicit action signals.

Back/Escape restores the Inventory entry and its native focus. Per-Actor local
chapter/page state lasts for the World Application session and resets on restart.
Absent values, removed entries and unavailable content retain readable states.
Actor placement remains the ordinary Actors drag-and-drop operation. Existing
captured targeted tabletop procedures retain their separate task route.

Authored source checks and disposable source fixtures may inspect native layout
and SDK boundaries without application setup. Retain the five focused Library
checks and two severe saved-capability/loot checks; remove the obsolete compact
375px composition matrix. These checks do not establish native acquisition,
render/input, network replication or durable application persistence.

RFG-354 owns unified native acceptance after official publication. Install the
exact public HTTPS Manifest normally and acquire World requirements through
normal join. Compare the actual authored sheet at the three canonical viewports,
including long text/loot, English/Russian, readable focus, current Actor state,
Owner/Viewer operations, Appearance return and durable close/reopen/rejoin.
Do not reuse the superseded compact Actor-sheet tour or copied Package stores.
