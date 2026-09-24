# Retained class actions and equipment

RFG-292 implements the approved first-playable class/equipment boundary. Rules
come from the supplied **MÖRK BORG Bare Bones Edition** OCR, printed equipment
pages 21–26, tests/combat pages 27–33, and optional classes pages 46–57.
`creation_classes.gd` retains the source names and descriptions; the Bevy fixture
is reuse evidence, not a replacement rules source.

All actions originate in the owning Character, equipped weapon, or Item view.
Class tests and consumable uses go through System actions and the generated
public SDK. Human Throws provide the physical Roll evidence. Accepted changes
and interpreted outcomes use the existing atomic Actor / Action Log capability.
No executable conditions, expiry, daily reset, Omen benefit, undo, replay,
resumption, allegiance subsystem, or new Props are introduced.

## Behavior ledger

| Class / retained entry | Immediate behavior | Table-managed boundary / source choice | Evidence |
| --- | --- | --- | --- |
| Fanged Deserter: Bite | Strength DR10, d6 at 5 ft; d6 free-attack chance | Resolve a granted enemy attack from its existing sheet | `special_weapons.gd` |
| Fanged Deserter: normal Agility / illiteracy | Existing ordinary DR14; existing Power refusal | No new rule | `ability_throw.gd`, `power_casting.gd` |
| Crumpled monster mask | Report the worn-mask rule | Lesser-creature eligibility; recurring Morale checks | `special_actions.gd` |
| Brown scimitar | Attack/defence DR10; d6 at 5 ft; wounded-target sepsis d6 | Death after ten minutes | `special_weapons.gd`, `player_defence.gd` |
| Wizard teeth | Four d6; report number of sixes | Assign and track maximum-damage attacks | `special_actions.gd` |
| Old Sigûrd's sling | Presence; 2d4 at 30 ft | Fist-sized rocks are source-described as ubiquitous | `special_weapons.gd` |
| Ancient gore-hound | Existing individual Creature, DR10 bite d6 / defence DR12 | Treasure scent and frenzy | Creation / companion / creature combat suites |
| Shoe of Death's Horse | DR10, d4 at 30 ft; d6 skull chance; immediate zero HP for agreed small/medium victim | Table confirms size; returns to hand (not ammunition) | `special_weapons.gd` |
| Gutterborn Scum: Stealthy | Existing ordinary Presence/Agility difficulty adjustment; ranged Presence and defence adjustment | Explicit printed class-test DRs remain their stated DRs | Modifier, melee and defence suites |
| Coward's Jab | Equipped light one-handed weapon: Agility DR10, normal damage +3 at 5 ft | Confirm surprise and light weapon; no ordinary critical damage multiplier | `special_weapons.gd` |
| Filthy Fingersmith | Agility DR8 | Pocket / lock fictional change | `special_actions.gd` |
| Abominable Gob Lobber | Confirm new fight, d2 uses; Presence DR8 at 30 ft; spend one spit; hit duration d4; selected witnesses test Toughness DR10 (PC) / DR12 (Creature) | Table chooses who witnessed it, including friends and foes; blindness/vomiting and rounds | `special_actions.gd` |
| Escaping Fate | Report the rule alongside ordinary manual Omen handling | Chance and all Omen benefits remain manual under the approved Omen boundary | `special_actions.gd` |
| Excretal Stealth | Report observers' Presence DR16 requirement | Hiding in filth and observer adjudication | `special_actions.gd` |
| Dodging Death | 50% chance with d4 (1–2); d4 return HP parameter | Eligibility, ten-round return and HP application are delayed | `special_actions.gd` |
| Esoteric Hermit: Master of Fate | Presence DR8 | Table describes the right way | `special_actions.gd` |
| Book of boiling blood | One daily use; enemy DR12; d2 count and d6 disposition; create printed Berserker-slayer Actors | PC resistance ability and enemy eligibility selected with table; place Rooks normally; allegiance and departure after battle | `special_actions.gd` |
| Speaker of Truths | Consume one of two daily uses; report next-test DR −4, 30 ft | Apply next-test benefit manually | `special_actions.gd` |
| Invisible College | One daily use; d2 count, d4 sacred/unclean family; add table-selected single-use scrolls; successful casting consumes scroll | Source does not select identities; unused scrolls become ash at sunrise manually | `special_actions.gd`, `power_casting.gd` |
| Bard / harp | Roll d4 reaction bonus | Apply bonus on reaction roll | `special_actions.gd` |
| Hawk as weapon | Existing individual Creature, DR10 attack/defence, d4, HP8 | Scouting and communication | Creation / companion / creature combat suites |
| Wretched Royalty: ancestral blade | Attack/defence DR10, d6+1 at 5 ft. Item use checks d6 treachery and resolves attack/damage against table-chosen self/ally, including shield choice | Source leaves continual disappointment, check occasion and victim choice to table | `special_weapons.gd`, `special_actions.gd`, `player_defence.gd` |
| Poltroon | Retained descriptive companion and printed first-two-round bonus | Track and apply +2 attacks/defences manually | `character_creation.gd` |
| Barbarister | Retained descriptive companion and printed conditional Presence bonus | Persuasion, logic/intellect eligibility and +2 benefit | `character_creation.gd` |
| Hamfund / Eurekia | Confirm Hamfund found and one draw per combat; 2d6 at 5 ft; every swing rolls d6; 1 slays recorded Hamfund and removes Eurekia even on a miss | Combat boundary/reset is explicit sheet correction | `special_weapons.gd` |
| Snake-skin gift | d4 at 5 ft; damage die 1 immediately sets victim HP to zero | None beyond normal target selection | `special_weapons.gd` |
| Schleswig horn | One daily use; Presence DR12, 30 ft | Apply next non-combat automatic success manually | `special_actions.gd` |
| Heretical Priest: crook | 2d4 at 10 ft; ordinary staff d4 against table-confirmed faithless humans | Faithlessness is a table choice | `special_weapons.gd` |
| Stolen mitre | Worn state grants defence DR10; outside-battle stealth DR8 with table-selected ability | Ears covered / outside-battle eligibility; no invisibility effect | `special_actions.gd`, `player_defence.gd` |
| List of sins | Presence DR10; target-directed 30 ft; report reveal and defence benefit | Table identifies evil and tracks +2 defence against revealed beings | `special_actions.gd` |
| Nechrubel Bible | One daily use on first accepted parity roll; d6 even/odd; odd d3 hallucination count | Even rest healing and odd hallucinations / sunrise expiry | `special_actions.gd` |
| Temple stones | Presence DR10; failure exhausts eligibility | Adjacent-room truth / lie and sunset reset | `special_actions.gd` |
| Wrong Jesus crucifix | 2d6 Morale, add or subtract Presence, 30 ft | Table confirms undead / lesser troll / goblin; supplies Morale if none printed; move/remove bowing creature manually | `special_actions.gd` |
| Priest medium armor | Existing Power permission | No new rule | `power_casting.gd` |
| Occult Herbmaster laboratory | Confirm daily eligibility; two d8 recipes and d4 shared doses; replace previous batch | Ingredients, daily boundary and 24-hour vitality | `special_actions.gd` |
| Red poison | Toughness DR12; failed resistance loses d10 HP; consume shared dose | Administering poison is confirmed | `special_actions.gd` |
| Ezumiel's vapor | Table-selected ability DR14; failure d4 hours; consume dose | Hallucinations | `special_actions.gd` |
| Southern frog stew | Table-selected ability DR14; d4 hours of vomiting even on success; failure prevents other actions; consume dose | Vomiting and duration | `special_actions.gd` |
| Elixir vitalis | Heal d6 capped at maximum HP; consume shared dose | Infection removed narratively; addiction adjudication | `special_actions.gd` |
| Spider-owl soup | Consume shared dose; report 30 minutes | Darkness sight / wall climbing | `special_actions.gd` |
| Fernor's philtre | d4 hours; consume shared dose | Eye application, infection and +2 Presence | `special_actions.gd` |
| Hyphos' snuff | Consume shared dose | Snorting/sneezing; two attacks and defence DR14 for a fight | `special_actions.gd` |
| Black poison | Toughness DR14; failed resistance loses d6 HP; consume shared dose | One-hour blindness | `special_actions.gd` |

## Other relevant equipment

| Equipment | Immediate behavior / boundary | Evidence |
| --- | --- | --- |
| Medicine box | d6 capped healing; spend use; report bleeding/infection clearance | `special_actions.gd`, `special_composition.gd` |
| Life elixir | d6 capped healing; spend dose; report infection clearance | `special_actions.gd` |
| Core red/black poison | Same printed resistance and HP procedure, own dose counter | `special_actions.gd` |
| Bomb / bear trap / caltrops | Table confirms triggered damage; human damage/protection dice; bomb consumed; caltrops d6 infection chance. No invented hit test or area | `special_actions.gd` |
| Food / water / lard | Consume one day / one day / one meal; no automatic rest/healing | `special_actions.gd` |
| Torch / lantern oil | Consume one item; report light (oil: Presence + 6 hours); no timer | `special_actions.gd` |
| Core scrolls / single-use College scrolls | Existing Power workflow with single-use consumption | `power_casting.gd` |
| Ammunition, ordinary armor and shield | Existing inventory, attack, defence and compact shield dialog | Ranged / inventory / defence suites |
| Other mundane tools / descriptive equipment | Existing inventory and editable quantities; no additional printed immediate mechanic | `character_inventory.gd` |

## Range, privacy, and termination

Distances use committed Rooks through the public SDK. Ordinary contact and
class blades use 5 ft; crook uses 10 ft; projectiles and targeted class powers
use 30 ft. Self use does not require a Rook. Fictional witnesses have no invented
radius: the table explicitly chooses them. If any selected range-constrained
target is outside reach, report every `target {public name} not in range` and
request no Throw. No line-of-sight test is added.

Authority reads the complete shared World. Owner checks govern mutation and
responsible Player routing; they never filter shared data. Public pending state
contains workflow facts, not private Creature sheets. Reports use public target
labels. Shield decision details are offered only to the responsible recipient.

Actions are live only. Closing, cancelling, removal, lost access or a replaced
required Participant session ends the action. Completed rolls, uses and HP
changes remain; late results and repeated terminal requests cannot apply twice.
Unsupported/malformed input is refused before new rolls or mutation. Day/fight
eligibility and remaining uses can be corrected explicitly on the owning sheet.

## Review regressions

Every continuation, including scroll selection and the shield decision, rechecks
source ownership, item existence and the pinned recipient's Rook/range. Accepted
bomb damage consumes the item before the shield decision; cancelling that decision
does not refund the bomb. Changed armor/shield protection ends a pending damage
interpretation. Taking caltrops damage preserves the infection result.

Class Agility tests apply worn medium/heavy armor penalties (+2/+4 DR, including
the original penalty tier after damage). The table can enter an additional DR
adjustment for load or fictional circumstances; the inventory does not infer item
size or encumbrance. Correcting Eurekia's remaining draws also clears its drawn
state for the next combat. No combat or rest timer resets these resources.

Ability and scroll choices use stock CheckBox radio behavior with scene-local
ButtonGroups. The Book previews the selected enemy, and malformed DR text requests
no dice. Tests cover independent sheet choices, source removal during a choice,
changed reach/protection, bomb cancellation, armor DR and the next Eurekia draw.
