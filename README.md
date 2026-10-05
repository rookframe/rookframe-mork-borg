# MÖRK BORG System Extension

This public repository is the sole source of the MÖRK BORG System Extension
Package for Rookframe. System rules, authored scenes, content and Package
releases belong here. Rookframe application capabilities belong in
[rookframe-godot](https://github.com/rookframe/rookframe-godot); shared authoring
capabilities belong in the SDK and reusable UI components in the UI Kit.

The first playable slices provide No Class and all six optional classes, editable
Character sheets, individual granted Creature Actors and imported Creature
definitions in the shared Library. Royalty receives two independent gifts, Priest receives its special
equipment, and Herbmaster receives two decoctions with one shared dose pool.

## Dependencies

[`plug.gd`](plug.gd) installs both dependencies from their public repositories:

| Dependency | Exact pin | Installed path |
| --- | --- | --- |
| [Rookframe SDK](https://github.com/rookframe/rookframe-sdk) | `v0.32.29` | `addons/rookframe_sdk/` |
| [Rookframe UI Kit](https://github.com/rookframe/rookframe-ui-kit) | `e2a1e807d73c907bf360aa38a21a55b1773965e2` | `rookframe/ui/` |

Use gd-plug for both. Do not copy SDK/UI Kit source from local checkouts or
maintain edited consumer copies. Installed dependencies and caches are ignored
by Git. `.rookframe/authoring.lock.json` records their versions.

The Package-local `sdk/` files are generated output of the installed public SDK,
as required by its authoring contract. Regenerate them with the SDK command;
do not hand-edit them or copy them from another project.

## Fresh clone

Use Godot 4.7.2, Python 3.10+, Git, curl and the .NET 10 runtime. Replace `godot`
with your Godot executable. Matching Godot export templates are needed to build
an archive.

```sh
git clone https://github.com/rookframe/rookframe-mork-borg.git
cd rookframe-mork-borg
mkdir -p addons/gd-plug
curl -fsSL https://raw.githubusercontent.com/imjp94/gd-plug/209276d1f00d14b49b74403d9839f29598e9a8eb/addons/gd-plug/plug.gd -o addons/gd-plug/plug.gd
curl -fsSL https://raw.githubusercontent.com/imjp94/gd-plug/209276d1f00d14b49b74403d9839f29598e9a8eb/LICENSE -o addons/gd-plug/LICENSE
godot --headless --path . --script plug.gd install
python3 addons/rookframe_sdk/rookframe_authoring.py facade --project .
python3 addons/rookframe_sdk/rookframe_authoring.py check --project . --godot /path/to/godot
```

The bootstrap URLs pin gd-plug itself. Only gd-plug installs the SDK and UI Kit;
no Rookframe application checkout is needed.

Build a new archive with the installed SDK:

```sh
python3 addons/rookframe_sdk/rookframe_authoring.py build --project . --godot /path/to/godot --output build/mork-borg.rookpackage
```

Use a fresh output path for each build. Commit authored files, dependency pins,
the authoring lock and regenerated facade. Do not commit installed dependencies.

## Distribution

[GitHub releases](https://github.com/rookframe/rookframe-mork-borg/releases)
publish the Package archive and public HTTPS Manifest. The
[public Catalogue](https://catalogue.prancing-dreadnaught.com/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/1.0.90)
provides discovery. Application setup and QA use normal Manifest installation
and automatic World-join acquisition; local archive imports and copied Package
stores are not part of this workflow.

## Character and inventory checks

Run the focused Godot suite with the installed public dependencies:

```sh
python3 tests/run_character_creation.py --godot /path/to/godot
```

The suite exercises authored System actions through the generated public SDK.
It covers all six optional class branches and their complete feature tables,
source origins, class dice, scroll choices (including repeated equipment
rerolls), late Roll/choice discard, atomic refusal/retry and companion projection.
Only the external host randomness/storage boundary is substituted. Host authority,
persistence and replication remain covered by the application's Package Services
suite and the published Manifest journey.

Bare Bones pages 46–57 and the retained Bevy optional-class creation branches are
the rules sources. Benefits, daily uses, Omen effects and durations remain table
managed. A Book of boiling blood or Invisible College feature does not summon
Actors during creation. The gore-hound and hawk use only their printed profiles.

Each atomic creation payload records a stable Package-owned creation request UUID,
allocated through the public SDK, and the first raw Roll's Action Log sequence.
The Character's companion list matches the UUID through the public Actor list;
the Roll sequence is provenance only because copied Worlds have fresh local logs.
SDK Actor access controls the visible results.

RFG-283 also covers repeated Royalty heavy-armor rerolls, duplicate gifts and
decoctions, the Priest’s physical 6/printed 666 result, all eight Herbmaster
origins and decoctions, explicit pack choices, and late class-roll discard.
Royalty’s three named companions have no printed combat profiles and remain
descriptive sheet data. Hamfund retains Eurekia as conditional equipment.
Starting dogs and monkeys remain individual Creature Actors.

The portable laboratory’s `uses` is the one shared remaining dose total; the two
recipe entries reference that pool and do not each receive a separate quantity.
The source does not allocate doses between recipes. Daily eligibility, brewing
in play, expiry, and ongoing effects remain at the table in this creation slice.
Horn, Bible, sword and laboratory remaining uses use ordinary completed-sheet
corrections; creation mechanics remain fixed until confirmation.

## Completed sheets

One Edit sheet button opens all Character values, including the played ability
modifier, current resources, class text and live equipment quantities/uses. The
core equipment catalogue creates independent carried items; custom live items
expose their supported mechanics. Item identities remain stable after removal.
Equip/unequip and Attack entries stay on their inventory item. Equipped 5 ft and 10 ft melee weapons resolve through the System on World Authority. The inline Omens −/+ counter changes only its remaining count. See [the compact Character sheet contract](docs/character-sheet-design.md).

Actor-default appearance and the selected linked Rook are separate choices from
available published Miniatures. The SDK authorizes and persists all writes. Open
sheets refresh replicated Actor state, preserve unsaved field text and clear their
private presentation when access disappears.

## Modifier Throws

Activate a Character modifier to request one physical d20 through the native Dice
Tray. The initiating Player rolls for their owned Character. A GM opening a
Character with one Player Owner sends the Throw to that Player; an offline Owner
is never replaced by the GM. With multiple Player Owners, the responsible Player
initiates from their own sheet. A Character without Player Owners is rolled by
its GM. Viewer access cannot originate an action.

The Action Log retains the unchanged raw Roll and a separate ability name,
modifier and total. This direct interaction supplies no DR: the table compares
the total with its agreed difficulty. It does not invent a success/failure or
apply situational modifiers automatically.

Closing the sheet, cancelling the tray or losing a required Participant ends the
action. Temporary tray hiding preserves the live sheet. Completed Rolls and
accepted sheet changes remain; late results never resume a cancelled action.
There are no recovery, undo or GM takeover controls. The focused ability suite
covers the System/public-SDK boundary; host lifetime, durable-save failure and
replication checks live in rookframe-godot.

## Weapon attacks

HUD Attacks uses the Actor's exact owned weapon or stable intrinsic action.
Unarmed uses Strength DR12 and d2; Improvised weapon asks for an object and
melee Strength or ranged Presence use with d4. Deserter Bite and Coward's Jab
retain their class rules. Inventory and HUD share their stars, including
unavailable favorites that remain until explicitly removed.

HUD targets are optional. With no target, the native tabletop action requests
an attack Throw followed by damage even after a natural 1 or would-miss result.
It reports both raw Rolls through the Dice Tray and Action Log. The table rules
on hits, criticals, fumbles, protection and damage recipients; this path has no
HP application or Apply damage step. Ordinary ammunition and an independent
Eurekia draw still spend the exact source resource once. The open action keeps
its Actor and source across HUD selection changes. The full-viewport sheet's
separate Attack/Damage and Window Dice behavior remains intact.

The Companions category projects only authorized companion Creature attacks.
Each favorite identifies the Creature Actor and its exact stat-block attack;
descriptive-only companions supply no invented combat action. Launch opens the
same captured native task bound to that Creature, using its flat test, damage
and matching Rook. Untargeted play uses the common attack/damage sequence;
supplied targets use the existing attack or defending Player workflow.
Remote defence requests open the existing defence-capable window, while
ordinary Character inspection still opens the completed full-viewport sheet.

Select the Character’s linked Rook, open its equipped weapon in Inventory, and
choose one Creature through tabletop targeting. Done restores the same managed
window and keyboard focus. Difficulty defaults to the source Creature rule;
the table can supply a difficulty or situational modifier and choose the printed
break/loss fumble alternative. Piercing is an explicit attack choice for the
skeleton’s printed DR. No Omen benefit or ongoing effect is automated.

The World Authority snapshots the prescribed attack and protection, validates
Owner access and the committed target set, and runs the human attack and damage
Throws through the native Dice Tray. Natural 20 doubles damage before protection
and lowers armor one tier after the hit; natural 1 applies the chosen equipment
consequence. Source Creature DRs and the skeleton’s destruction threshold come
from Bare Bones pages 58–62. Ordinary melee comes from pages 28–29. The Bevy
weapon-attack-rules and weapon-attack-executor at 61ea4098 provide reuse evidence.

One tabletop unit is one metre. Authored reach is explicit: 5 ft = 1.524 m and
10 ft = 3.048 m and 30 ft = 9.144 m. The SDK measures committed logical Rook centers, without line of
sight. Every out-of-range target is reported as `target {public name} not in range`;
an invalid set stops the entire action. All Participants receive the complete
World state, including Creature data. Privacy is only UI display: inaccessible
sheets stay hidden and action text uses public labels. Consequences do not grant
the Player additional display or action access.

Action identities belong to one live Participant session. Duplicate calls retain
the existing result. Closure, cancellation, lost access or a required session
ending prevents further interpretation. Completed raw Rolls and accepted HP,
armor, equipment and public reports remain; reopening does not resume an action.
The focused melee suite exercises this through generated public SDK actions,
with only the external host boundary substituted.

Melee d2 damage or protection uses a physical d4: 1–2 gives 1, 3–4 gives 2.
The raw d4 remains in the Roll record; the result explains this conversion.


Bow, shortbow, crossbow and sling attacks use Presence. Gutterborn Scum retains
its printed −2 Presence DR. Bow/shortbow spend one arrow and crossbow spends one
bolt when the accepted attack roll is interpreted, including misses and fumbles.
The action view identifies the next available matching stack in inventory order.
Single ammunition items use quantity; bundles use remaining uses. A cancelled
pre-roll action spends nothing; ending after the shot preserves the accepted
spend, raw Roll and report. Sling and unrelated use counters are not depleted.
Custom weapons without authored attack rules retain only the supported 5/10-ft
melee case; choose the core catalogue for a ranged attack.

Creature Stat Block exposes every authored alternative before reach validation,
including Goblin knife/shortbow and Grotesque claws/eye-beam. Existing saved core
Actors receive these choices without replacing their live damage or sheet values.
Contact, extended and projectile alternatives have separate 5/10/30-ft reaches;
source attack DRs, automatic hits and table-managed special consequences remain
visible on the selected action. Creature attacks request the responsible Character owner’s defence. Companion
attack resolution and class special actions remain owned by RFG-291 and RFG-292.


## Player defence

A GM selects an equipped Creature attack and one Character target. The connected
Player owner receives an Agility defence in their existing sheet; multiple owners
require an explicit choice. A Character with no Player owner is handled by the
initiating GM. Creatures do not roll an ordinary attack. Printed automatic-hit
attacks request damage directly. Medium/heavy armor adds its printed defence
penalty. The table may agree a difficulty or situational modifier.

On a failed defence the defender throws damage and armor protection. Natural 20
reports a free attack for ordinary weapon selection; natural 1 doubles damage
before protection and reduces armor one tier, retaining its penalties. Shield
reduction applies before a compact 368 × 224 decision offers the current HP
consequence or destruction of one shield to ignore that attack’s damage. Closing
the decision terminates the action; already rolled dice and accepted armor damage
remain. Participant disconnect, loss of ownership, and closure cannot resume the
action or transfer it to the GM. Effects, Omens, timers and unfinished outcomes
remain table-managed. SDK 2029 revision 14 supplies the live session boundary.

## Automated tests

All extension suites use official GdUnit4 6.2.1, pinned by commit in `plug.gd`
and verified with stock Godot 4.7.2 Mono. Install development dependencies and run:

```sh
godot --headless --path . --script plug.gd install
python3 tests/run_character_creation.py --godot /Applications/Godot_mono.app/Contents/MacOS/Godot
```

The runner discovers every suite under `tests/` (24 cases at migration),
imports resources, and requires a fresh nonempty passing JUnit report. Reports
are written under `reports/<run>/report_1/` as XML and HTML. Failures, native
errors, timeouts, orphan Nodes and skips fail the run. Tests extend
`GdUnitTestSuite`; use `test_*`, native assertions, `auto_free` and signal/await
completion. The host boundary is substituted where required; real host and
platform acceptance checks live in rookframe-godot. Tests, reports and GdUnit
are excluded from Package exports.

## Core Power casting (RFG-289)

Owned core scrolls have Cast entries in Inventory and the Powers & scrolls view.
All twenty definitions retain their Bare Bones pp. 34–35 rules and an explicit
handling classification. Foul Psychopomp materializes individual Creatures as described below.
Catalogue text is not a claim that the summon action works.

Ordinary casting requests a human Presence d20 against DR12 (the Scum’s printed
Presence reduction gives DR10). Success spends one daily use; ordinary failure
requests physical d4-as-d2 HP loss without spending a use. Dizziness lasts one
hour and is table-managed. Before casting, the table confirms that the caster is
not dizzy and the Power’s fictional requirements are met. Medium/heavy armor,
zweihand weapons and Deserter illiteracy block casting; the Priest can use medium
armor. The explicit morning button requests Presence + d4; there is no clock or
automatic daily refresh. Sheet corrections remain available.

Natural 1 and 20 finish with “Power fumble/critical: GM determines the outcome.”
No catastrophe, damage multiplier, ruling form or waiting state is invented.
Other supported Powers request their printed quantities and report manual
outcomes. Nine Violet Signs reports each bolt without assigning damage; Death
reports its shared 4d10 total without allocating it. Aegis never writes temporary
HP and Unmet Fate never invents restored HP. Ongoing damage, movement, answers,
commands, bonuses, sleep and expiry remain at the table.

Eyelid rolls d4, asks for that many distinct targets, then requests the GM’s
unmodified Creature resistance dice against DR14. The source leaves PC ability
selection unspecified; the report preserves that manual test boundary. Selected
targets use authored 30-ft range (9.144 tabletop units), with all out-of-range
targets reported by public label. Death’s area and Telekinesis movement are
separate from casting range. An unrepresented object is agreed with the table.

Power actions use existing public SDK System intents and session-bound requested
Throws. Closing, loss of ownership or a required session ending terminates them;
accepted daily-use changes and raw Rolls remain. The focused `power_casting.gd`
and `power_composition.gd` suites cover this seam and authored UI. App acceptance
uses the published Manifest with the existing RFG-281 `--powers-only` journey.

Casting metric strips use two columns below 480px. Presence is a small label
with the signed modifier as its value, avoiding the approved fixture’s split
word in the phone dock. Natural critical/fumble results use a terminal report
with the natural face, result and ordinary Character/Done navigation.

## Immediate Power consequences (RFG-290)

Palms and Grace request d2 creatures (physical d4 halved, rounded up); Roskoe
requests d4. Confirm exactly that many distinct Character or Creature targets
within 30 ft, then throw independently for each. Grace restores d10 HP up to
maximum HP without resurrecting a dead target. Roskoe removes d8 HP directly.
Palms deals d8 damage reduced by equipped, intact armor and the shield’s −1;
damage cannot fall below zero. This situational Palms ruling was approved on
24 September 2026 following the creator’s specific clarification. Breaking a
shield against Palms stays with the table: close the action before applying
damage, then resolve it with ordinary dice and sheet edits.

Targets are frozen at confirmation and the whole set is revalidated before one
durable multi-Actor commit. Changed links, range or protection, malformed data,
failed saves and interrupted sessions cannot cause partial or late HP changes.
The accepted casting use and raw Rolls remain. Reports use public target names
and reference all casting, count and consequence Rolls. Allocation, temporary
HP, resurrection HP, ongoing effects and critical/fumble rulings stay manual.


### Individual summons and granted Creatures (RFG-291)

Foul Psychopomp requests its source d6 type and d4 count after an accepted
casting test. SDK 2029 revision 15 atomically materializes individual skeleton
or zombie Actors with the supplied profiles and ordinary Owner access for the
caster's controlling Participant. The action retains its casting use, raw Rolls
and one terminal report. Cancellation, disconnect, lost access, failed saves,
restart and repeated requests cannot create late or duplicate summons. No
allegiance, duration or automatic Rook placement is added.

Starting and summoned Creatures share the Character's Companions list. Open
sheet and Place Rook address each individual Actor. Explicit stat-block attacks
validate that Creature's own selected source Rook and authored reach. An owned
Creature attacking a Character requests the defending Character's controlling
Participant. Granted Creatures also request their responsible Player’s flat defence. Attacks
against unowned Creatures use the acting Creature’s flat d20, with DR12 plus
independent printed difficulty adjustments. A single strike uses one hit test.
This table ruling was approved in RFG-291 after research into printed rules and
creator practice; the owner’s Character abilities never apply. Ordinary damage,
armor and criticals apply through the recorded Creature Stat Block. Creature
fumbles are table adjudication and never change carried loot. Situational DR
and modifier choices remain available.

Owner Players can add catalogue loot or custom items, edit supported fields,
quantities and uses, and remove entries from each Creature's Inventory. Loot
has no Equip, Cast or Use action, and changes no Creature capability. Initial
loot is explicitly authored separately from attacks and natural protection.
Older saved Creatures retain their effective attacks, protection and carried
entries on their next accepted edit. Removed attacks do not return. Creature
combat uses that independent Stat Block; it never spends ammunition or damages
carried loot. Targeted tabletop criticals can reduce recorded protection without
changing an inventory item. Full-sheet interactions have their own table-resolved
consequence boundary.

## Class abilities and consumables

Retained class actions and special equipment use the owning Character, equipped
weapon or Item view. The [behavior ledger](docs/class-actions.md) records every
class entry, immediate outcome, range, source choice and manual boundary.
Daily/fight eligibility is confirmed at the table; remaining uses are editable,
and ongoing effects and all Omen benefits stay manual.

## Recovery, improvement and Broken (RFG-293)

Rest, Level up and Broken & death are Character-sheet actions. The table
determines when rest occurs; only food/drink and infection have sheet controls.
Recovery requests a human
d4 (catch breath) or d6 (full sleep), caps healing at maximum HP and never
replenishes Omens. No food/drink or infection restores no HP; daily loss remains
manual. Negative HP means dead and rest cannot resurrect the Character.

When the GM calls for improvement, an Owner begins directly from Level up. There
is no authorization button or stored grant. Human Throws resolve
6d10 against maximum HP (equality qualifies), the conditional d6 maximum-HP increase,
d6 debris, conditional 3d10 Silver, and one d6 per ability in order. Increasing
maximum HP does not heal current HP. Found sacred/unclean scroll identity is chosen
with the table; the source supplies only its family. The ordinary scroll is added
to Inventory. Abilities stay within −3…+6, including the special low-ability rule.
Gutterborn Scum gains a second rolled specialty on the first improvement and may
keep or reroll either/both on later improvements. Starting-only equipment is not
re-granted. Interrupted improvements retain accepted steps;
finish unfinished steps with ordinary dice and sheet corrections. The completed
sheet exposes improvements begun and both Scum specialty slots (source d6 number;
0 leaves the second slot empty) so manual completion does not strand later play.

At zero HP, Broken requests d4 and the prescribed injury/recovery parameters.
Unconsciousness, limb/eye loss, hemorrhage and death are reported. Delayed recovery
never changes current HP or creates conditions/timers. Hemorrhage d2 uses physical
d4 (1–2 → 1, 3–4 → 2); the report retains the source's first/last-hour DR wording.
Negative HP reports death directly without another Broken roll. Class exceptions
remain available from their existing class actions and table adjudication.

Rules: Bare Bones OCR pp. 29, 31, 33 and 49, plus its quick-reference infection
entry. The main Rest extraction omits daily starvation/infection damage clauses;
they are not interpreted as absent or automated by this action. Eligibility,
fictional time, conditions, daily loss, Omen benefits, and delayed HP application
remain manual. The September 27 compact Character correction supersedes the old docked health
composition and removes confirmation checkboxes. Existing public SDK System intents own authorization, persistence,
complete World replication, raw Throws and Action Log commits. No new host API,
transport, Prop, effect engine, resumption, Undo or GM takeover is introduced.

## Encounter guidance

Select a linked Rook on the tabletop and use its swords action to add or remove
that Rook from combat. Rooks remain separate even when linked to the same Actor.
The GM's Encounter window advances Players and Monsters, with equal Previous and
Next buttons, a quiet initiative die beside the sides, and round correction / End
behind the round numeral. Every Participant sees a horizontal Miniature sequence.
Selecting an entry opens its GM encounter actions without changing initiative.
Guidance never gates actions or processes effects or fictional time.

Group initiative requests one physical d6 (1–3 Monsters, 4–6 Players). Wrat Wraith
acts first, before the ordinary side phases. The optional individual initiative
procedure is outside this compact two-side surface; there are no score or bonus
editors. Reaction requests 2d6 and uses the five printed bands. Morale requests
2d6 against numeric Creature Morale; only a strictly higher total requests the
separate physical d6 (1–3 flee, 4–6 surrender). Trigger timing and qualitative
special Morale stay with the table. No Actor HP is changed by guidance.

Current guidance is stored under `encounter` in Package-owned World data. All
Participants receive the complete state; access only controls local presentation.
GM actions use revision checks and atomic World-data publication. Closing a
pending tracker cancels its current requested Throw; returning opens current
guidance. Restarted sessions do not resume actions. Raw Rolls and public outcomes
remain in the Action Log; corrections change current values without replay.

The initiative display uses miniature previews. There is no separate portrait
selection, reveal workflow, or stored portrait value.

Rules source: Bare Bones, Violence/Initiative/Reactions/Morale and Wrat Wraith.
Presentation follows the conventional roster/round/next-turn controls in
[Foundry](https://foundryvtt.com/article/combat/) and
[Roll20](https://help.roll20.net/hc/en-us/articles/360039178634-Turn-Tracker), with
[Baldur's Gate 3's portrait turn order](https://www.baldursgate3.game/news/patch-2-now-live_89)
as the shared presentation reference, following the user's RFG-294 instruction.

## Languages

Version 1.0.81 includes Russian to the Package UI and authored class, Creature,
equipment, trait, origin and scroll descriptions. Choose **Русский** in
Rookframe → Settings → Game settings → Language before opening the World.
English remains the Package default for unsupported application languages.

The Manifest declares ordinary Godot `Translation` resources at `i18n/en.tres`
and `i18n/ru.tres`. Authored views receive the generated SDK's translation
capability through `localize()` and translate complete templates before formatting.
The two rail entry scenes select their authored Russian copy through the same
Package catalog; the rail API itself does not inject an SDK into Button scenes.
There is no global catalog registration or host-node search.

Names, custom item names, editable values, IDs, dice requests, gameplay data and
recorded Action Log reports keep their original values. Language is local to each
Participant; changing it does not rewrite the shared World or its history.
Both original and Russian names can be searched in the equipment/Creature catalogues.

`tests/localization.gd` covers Russian creation and inventory rendering, translated
search, English fallback, untouched user input and drafts, format argument parity,
and coverage of every authored class, equipment, Creature and scroll description.
Keep English IDs and action-state comparisons separate from translated display copy.

## Creature Miniatures

The Game Master can choose a Miniature on a Creature library entry. This is a
World-specific default: every new Creature made from that entry receives the
current choice, while existing Actors keep theirs. Clearing the default affects
only future Actors. Published library definitions are never edited.

An Actor Owner can choose another Miniature in that Creature's sheet. The shared
UI Kit browser searches Rookframe’s built-in Miniatures and available Miniatures from enabled World Packages,
shows their source Package and previews the selection. Back discards a draft;
Use Miniature saves it. Missing content keeps its stable reference and asks for
a replacement instead of silently picking another model.

Place Rook uses this Actor's choice in the current Scene. Existing Rooks retain
their appearance. Change selected Rook explicitly updates only the selected Rook
linked to this Actor, preserving its identity, placement and hidden state.

Both journeys and browser states are available in English and Russian. Miniature
names use their owning Package's translations, falling back to its original name.
The System ships no Miniature models. Scum, Goblin and Berserker definitions use
Rookframe’s Bandit, Goblin and Barbarian respectively. Other Creatures implicitly
use Rookframe’s Default Miniature. Explicit Actor and library choices take priority.
See [Miniature ownership and defaults](docs/miniatures.md).

## Library and Actor navigation

Rookframe owns the right rail in the order Actors, Scenes, Library, Builder, Menu.
MÖRK BORG adds no Creature catalogue window. Its imported Actor Definitions appear
in Library under Creatures. Opening one shows a separate Full-viewport definition sheet;
Its Appearance chapter owns World-local portrait and Miniature defaults for new Actors. Portraits retain original PNG/JPEG/WebP files in the shared World; Actor and Library values store World-relative filepaths. Synchronous System saved-data callbacks convert earlier inline portraits before Authority startup and Participant admission, including on dedicated Authority, preserving their existing bytes and gameplay data. An unsuccessful conversion refuses startup and keeps the failed saved value for retry. The + button on its
Library row and Create Actor on its sheet create Actors. Dragging a
Creature onto the tabletop creates an Actor and a linked Rook at the drop position.
Creation is a GM operation. Failed placement cleans up its partial Actor and Rook.
Character creation is contributed to the shared Actors window.

## Creature Actor sheet

Live Creature inspection, Library creation and companion opening use the shared fixed Full-viewport Creature sheet. Encounter, Inventory and Appearance keep current Actor values, independent carried loot and SDK appearance operations together. Portrait image choice/reset and Miniature changes commit immediately outside stat-block Save/Cancel. Library defaults snapshot only into future Actors; existing Actors and Rooks keep their appearance. Owner loot and appearance edits preserve the current stat block; Viewers can read it. Bounded Details return to the entry and focus, and Actor-local chapter/page state lasts for the World Application session. Corrections, HP adjustments and Window Dice are enabled by their dependent rule adapters. Existing captured targeted tabletop procedures retain their separate legacy task route. Actor placement stays in the Actors drag-and-drop flow.

Creature corrections use desktop inline fields, a bounded tablet Window, and a full phone chapter. One changed-fields draft retains native typing/focus and merges only changed values into current accepted data; Back keeps it, Cancel/Escape discards it, and loot/Appearance remain independent.

Creature Inventory keeps a bounded carried-loot list with readable Details, a searchable core catalogue, custom item creation, independent field saves and removal. Character equipment retains its existing Attack/Equip/Cast/Use behavior. See [the review contract](docs/creature-sheet-design.md).

## Character HUD

SDK Edition 2029 revision 27 mounts the System-owned native Character HUD above
floating windows and below docks and full-viewport tasks. Its Owner context uses
an owned selected Rook or a Player's sole owned Actor; GM and multiple-Actor
Players require selection, and available Prop controls take precedence.

The approved revision-8 bar uses live portrait/HP, native Dice Tray and completed
sheet entry points, and all four existing Ability Requested Throws. Starting a
Throw retains its Actor across later HUD selection changes. Desktop, tablet and
landscape phone share categories, anchored panels and bounded paging; phone uses
More and the four-Ability grid. Other categories remain empty until their own
RFG-338–342 slices supply real entries and domain handoffs. Favorites are not
seeded or persisted by this presentation slice.
