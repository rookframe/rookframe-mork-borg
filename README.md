# MÖRK BORG System Extension

This public repository is the sole source of the MÖRK BORG System Extension
Package for Rookframe. System rules, authored scenes, content and Package
releases belong here. Rookframe application capabilities belong in
[rookframe-godot](https://github.com/rookframe/rookframe-godot); shared authoring
capabilities belong in the SDK and reusable UI components in the UI Kit.

The first playable slices provide No Class and all six optional classes, editable
Character sheets, individual granted Creature Actors and the private Creature
catalogue. Royalty receives two independent gifts, Priest receives its special
equipment, and Herbmaster receives two decoctions with one shared dose pool.

## Dependencies

[`plug.gd`](plug.gd) installs both dependencies from their public repositories:

| Dependency | Exact pin | Installed path |
| --- | --- | --- |
| [Rookframe SDK](https://github.com/rookframe/rookframe-sdk) | `v0.23.0` | `addons/rookframe_sdk/` |
| [Rookframe UI Kit](https://github.com/rookframe/rookframe-ui-kit) | `0c152a804332dd5571caa8a2c3dd161aa21fb7f7` (`v1.0.0-rc.1`) | `rookframe/ui/` |

Use gd-plug for both. Do not copy SDK/UI Kit source from local checkouts or
maintain edited consumer copies. Installed dependencies and caches are ignored
by Git. `.rookframe/authoring.lock.json` records their versions.

The Package-local `sdk/` files are generated output of the installed public SDK,
as required by its authoring contract. Regenerate them with the SDK command;
do not hand-edit them or copy them from another project.

## Fresh clone

Use Godot 4.7.2, Python 3.10+, Git, curl and the .NET 8 runtime. Replace `godot`
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
[public Catalogue](https://catalogue.prancing-dreadnaught.com/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/1.0.33)
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

Completed Characters support field-local corrections, including the played ability
modifier, current resources, class text and live equipment quantities/uses. The
core equipment catalogue creates independent carried items; custom live items
expose their supported mechanics. Item identities remain stable after removal.
Equip/unequip and Attack entries stay on their inventory item. Equipped 5 ft and 10 ft melee weapons resolve through the System on World Authority. Spending an Omen changes only its remaining count.

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

Creature inventory exposes every authored alternative before reach validation,
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
handling classification. Foul Psychopomp remains unavailable until RFG-291.
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
sheet and Place Rook address each individual Actor. Equipped Inventory attacks
validate that Creature's own selected source Rook and authored reach. An owned
Creature attacking a Character requests the defending Character's controlling
Participant. Creature-versus-Creature combat remains unavailable pending the
explicit source-rule decision tracked in RFG-291; this release does not invent
a roll convention for that case.
