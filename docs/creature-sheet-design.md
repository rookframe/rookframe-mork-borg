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

Each ordinary loot overview entry keeps its name, quantity, kind and Details
action in one native button, so the existing measured pager cannot strand a
context-free Details tail. If the complete wrapped name makes that button taller
than the available page, the full name remains paginated text above a compact
action that repeats the name, quantity and kind. Only that repeated name may use
native ellipsis; the complete name stays in the text, Details and accessible name.
Neither branch limits the collection or adds scrolling. Details shares the
Creature article typography while retaining the existing independent item-field
saves, custom/catalogue addition and removal.

Appearance commits portrait choice/reset and preferred-Miniature changes
immediately, independently of the stat-block draft. The host-owned portrait
picker retains original PNG/JPEG/WebP files in the shared World and returns
World-relative filepaths through the public SDK. Actor and Library mutations
save only those paths; Reset restores the authored portrait. Synchronous System
saved-data callbacks convert earlier inline portraits before Authority starts
and admits Participants, including on dedicated Authority. Update a stopped
World’s selection to the newly published filepath System first; the replaced
inline-byte Package facade is not a retained gameplay compatibility API. The existing full-viewport Miniature browser provides
name/Package search, None, preview, Cancel and Use Miniature. Existing Rooks
keep their Miniature. Owner mutations reread the latest accepted Authority
Actor and freeze legacy effective capabilities on the first appearance write.
GM Library choices persist in Package-owned World data as defaults for future
creation from that entry; creation snapshots the current Authority defaults.
Changing defaults leaves existing Actors and published definitions unchanged.
Each image choice captures only its prior portrait filepath and portrait revision
before selection/upload. Authority checks both against current data and increments
the portrait revision on every accepted choice/reset. The per-Actor field and
per-definition World map prevent a late upload replacing a newer choice or reset,
including an empty → choice → empty cycle. HP, loot and unrelated World changes
do not invalidate an otherwise current portrait choice.

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
checks, two severe saved-capability/loot checks, two severe correction checks
and the severe first-appearance write/stale-data check; remove the obsolete compact
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

## Creature HP and Dead

The live HP ± control opens a bounded Apply damage / Heal reader outside Edit
sheet. Enter the positive whole amount already resolved at the table. Authority
reads current accepted Creature HP, applies that net subtraction/addition once,
and commits through the public SDK. It performs no armor, attack, Roll or target
procedure. HP may become negative or exceed maximum HP; maximum HP is not a
healing ceiling. During Edit sheet the same control opens the shared core draft,
with no immediate HP operation. Save/Cancel keep their existing semantics.

Dead is derived only from an accepted integer HP value at zero or below. Rules,
loot, Appearance and permitted corrections remain available. Accepted positive
HP restores gameplay eligibility. Missing, string, fractional or boolean HP does
not fabricate Dead: the sheet shows the saved value, indicates that HP needs
correction, disables relative adjustment/rolls, and offers Edit sheet. There is
no Character Broken incident, recovery timer or general condition framework.

`logic/creature_health.gd` supplies `valid(data)`, `is_dead(data)` and
`can_roll(data)` for accepted Creature data. The live adapter exposes `is_dead()`
and `can_roll()`; the latter also checks Owner, operation pending and the shared
draft. RFG-351 must use this predicate on Authority before starting gameplay
rolls, and accepted `current_data()` for UI initiation. Draft HP is never input
to the accepted condition predicate.

`CreatureActions.adjust_health(id, operation, amount, transport)` submits only
`creature-health.adjust` with Actor identity, stable request identity, `damage`
or `heal`, and text amount. The live reader retains the same identity/choices
through automatic transient transport retries and an unchanged retry after an
error. Authority binds accepted identities to the initiating Participant session
and exact choices, records acceptance before readback, and returns fresh Actor
state on a duplicate acknowledgement without another write. These transient
receipts have the running Authority lifetime; a new session/reopened sheet starts
from the accepted Actor rather than resuming a private request. Close/rebind
guards late presentation replies without rolling back an already accepted write.

Creature integer corrections and amounts reject values outside stock Godot's
signed 64-bit integer capacity before conversion. Relative arithmetic checks that
capacity before adding/subtracting. This prevents verified wraparound and leaves
valid signs, leading zeroes and above-maximum gameplay HP intact. Validation is
atomic and field-local. Native rendering remains coalesced; portrait cache,
Appearance pending behavior and correction/portrait epochs retain their separate
boundaries.

## Named Creature rolls

Ordinary enemy attack rows offer Damage directly. Damage, Protection, fixed
Morale and explicitly authored printed dice run through existing physical
Window Dice and ordinary Action Log outcomes. They need no target, Player,
source Rook, range, Dice Tray assembly or throw gesture. Complete special-rule
prose stays manual; the action writes no Actor, target, loot or condition data.
Armor rolls report protection only, and morale reports its captured threshold
without applying a response. Ordinary enemies do not gain their own Attack or
Defence test from Owner access or a printed opposing Player difficulty.

`logic/creature_rolls.gd` resolves an accepted named capability and validates one
supported dice pool plus its signed integer modifier. Each d2 is a physical d4
face mapped independently (1–2 to 1, 3–4 to 2), then summed before the modifier.
`2d2+3` with physical faces 3 and 3 is 7. Formula capacity validation prevents
integer wrap; unsupported formulas stay readable and require correction/manual
resolution. No arbitrary prose or generic dice-rule parser is introduced.
The captured original formula remains intact. Equivalent normalized expressions
keep outcome summaries concise; long identity excerpts and printable report
text honor the SDK's UTF-16 title/text limits without limiting saved sheet data.

Semantic `creature-roll.start` takes `id`, `source`, `part`, `entry`; the parts
are `damage`, `attack`, `defence`, `armor`, `morale`, or
`printed:<authored-roll-id>`. Authority checks
the current initiating Participant session, fresh Owner access and accepted
health, then captures Actor identity/name, capability identity/name, formula and
physical plan. `advance`/`cancel` take the same action `id`. Immutable raw plan,
faces, Participant and sequence are validated before one atomic empty-gameplay
commit publishes the interpreted outcome. Repeated completion acknowledges the
cached result. Failed storage ends that workflow without a report; abandoned
or late raw results cannot publish. A recorded request from an earlier Authority
lifetime cannot restart under the same identity.

The authored `RollWorkflow` scene child owns the existing `melee_action` /
`action_request` transport, polling and `sdk.dice.roll_requested(request, root)`.
It exposes `pending`, `source`, `state`, `snapshot`, `summary()`, `start()` and
`abandon()` to the coalesced sheet adapter. Owner/Edit/pending/accepted-health
guards remain in that adapter and the fresh Authority boundary. Closing hides
presentation and preserves a pending Roll; reopening its initiating Actor can
present it again. Actual authored content removal/free invokes the stock Godot
`RollWorkflow._exit_tree` hook and abandons through the existing independently
retained `action_request` cancellation. That transport orders cancellation after
a delayed accepted start even if its UI Node has already been freed. A host
Actor-window content replacement therefore cancels the old action instead of
leaving a request with no poller. Hiding/Close retains the Node and pending Roll.
Opening a different Actor cannot redirect that request. Back,
chapter change or another workflow abandons unfinished dice. The reader retains
identity/portrait on phone and restores the exact named opener after layout.

`logic/creature_own_tests.gd` determines separate flat own Attack/Defence tests
from accepted rule/origin evidence. Hawk and Ancient gore-hound have explicit
profiles. Dog/monkey require their actual nonempty `creation_id`; supported
Belze/Nodh summons require nonempty `summoner_actor` and `summon_action` with
`grant_source: Foul Psychopomp`; Zukuma requires the same origin pair with
`grant_source: Book of boiling blood`. Access alone supplies none of these rules.
Attack uses the accepted own `attack_dr` or retained flat DR12. Hawk/hound
Defence uses their accepted own `defence_dr`; the supported enemy-derived
summons use `24 - defence_dr` for their recorded opposing difficulty. Situational rules
stay manual. Buttons, readers and outcomes show the current accepted own DR;
only exact known default prose is refreshed, while custom prose stays intact.
Granted profiles without an authored Defence row gain a presentation-only row.
No Character ability, target information or Player defence readout is used.

Own d20 natural 20/natural 1 report Critical/Fumble; other faces report the base
comparison to captured DR, with modifiers and consequences explicitly manual.
Attack never chains Damage. Each accepted Attack replaces its Actor's transient
context, capturing the stable source attack ID, known correction tag, immutable
named Damage formula/plan and Attack Raw Roll sequence. Matching Damage uses
that initiating Damage choice; a critical doubles its complete result after each
d2 face conversion and modifier. Integer overflow ends without acceptance.
The context is consumed only after a matching Damage report commits; unrelated
Damage remains ordinary, failures/retries cannot consume/report twice, and a
newer accepted Attack prevents late pending Damage consuming the newer context.

Known nonempty correction tags must match exactly; removal or changed tag
invalidates the old context. Legacy untagged matching requires the same Actor
and exact nonempty source attack ID still present, with no known replacement.
The first semantic Edit preparation may bind its newly assigned tag, preserving
the captured formula/plan. No label/index/access inference recovers unknown
origin or identity history. Context is Authority-lifetime state, with no new
World or Actor fields; restart does not reconstruct a preceding Attack.
Two narrow retained severe SDK cases cover accepted-once/failed/late completion,
critical identity/consumption and independent data preservation; ordinary guards,
localization and authored focus
are disposable checks. RFG-354 still owns actual native dice, accepted logs,
public Manifest acquisition and application persistence proof.
