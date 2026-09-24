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
| [Rookframe SDK](https://github.com/rookframe/rookframe-sdk) | `v0.21.0` | `addons/rookframe_sdk/` |
| [Rookframe UI Kit](https://github.com/rookframe/rookframe-ui-kit) | `9de97beeede7f9d803e6ea0abef67730cdc84692` (`v1.0.0-rc.1`) | `rookframe/ui/` |

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

## Melee attacks

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
10 ft = 3.048 m. The SDK measures committed logical Rook centers, without line of
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
