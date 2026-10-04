# Character HUD recovery

The fixed Recovery list contains Catch breath, Full night’s sleep and Regain
Omens. Its right-hand values are d4 HP, d6 HP and the Character's printed Omen
die. These entries do not participate in Actor Favorites or require a target.
Unavailable actions stay grey. The shared HUD controls desktop/tablet Recovery
and phone More → Recovery composition.

`ui/hud_recovery.gd` exposes `bind(sdk)`, `entries(actor)` and
`launch(actor_id, key)` with stable keys `breath`, `sleep` and `omens`. Launch
opens an authored managed Actor task through the public SDK. The task captures
its initiating Actor and refuses a replacement while its recovery is pending.
Closing cancels unfinished work; reopening prepares the explicitly selected
recovery with a fresh action. Existing full-viewport sheet routes remain intact.

Catch breath and a full night's sleep retain the health authority's d4/d6 HP
recovery, capped at maximum HP. Food/drink and infection are explicit workflow
choices. Without food/drink or while infected, rest restores no HP; daily loss
remains table-managed. Rest never replenishes Omens, Powers or class/day uses.

Regain Omens requires zero remaining Omens and confirmation that at least six
hours of rest have passed. The authority rolls the printed class Omen die:
classless, Deserter, Scum, Royalty and Herbmaster use d2; Hermit and Priest use
d4. Physical d2 uses the existing d4-halved-and-rounded-up convention. Before
committing, the authority checks current Owner access, depleted Omens and the
same Omen die again. The accepted result changes only this Actor's Omens and
records its Raw Roll in the Action Log.

These distinctions follow the [official Bare Bones rules](https://jnohr.itch.io/mrk-borg-free),
printed pp.31,37,46–57, and the host's source-backed MÖRK BORG HUD workflow audit.
Both workflows use the existing health System authority and ordinary human
Throws in the tabletop Dice Tray. Native evidence and its limits are recorded
in [RFG-342 verification](evidence/rfg-342/README.md).
