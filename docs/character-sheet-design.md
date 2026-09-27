# Compact Character sheet

The September 27 user correction supersedes the old Character/Omen and health
workflow compositions. Keep the unchanged Rookframe UI Kit and stock Godot
containers, Buttons, Labels, CheckBoxes and ScrollContainer.

Character starts with the class and one 24px Edit sheet icon. HP, Omens and Silver
share a compact strip. Omens has named 24px decrease/increase controls and a
reserved 28px value lane; zero disables decrease, a pending save disables both,
and a failed save keeps the committed value with inline error text and retry.
All four modifiers remain direct roll controls. The single editor includes every
resource and ability plus the existing profile fields; remote changes preserve
dirty fields. Viewer access disables changes and hides the edit entry.

Rest, Level up and Broken/death form one short wrapping action row. Combat and
Powers/Companions use dense summary rows with accessible inventory, Power and companion icons. Profile
copy uses intrinsic height; empty description, origin, traits and action groups
are hidden. Actionable traits show their rules once, beside the action.

Rest shows the two recovery choices, HP, Food & drink, and Infected. Those two
booleans affect actual healing and remain; the redundant eligibility checkbox is
removed. Level up starts directly for an Owner when the table calls for it; there
is no persistent GM grant, authorization button or permission wait. Broken still
requires 0 HP; negative HP still reports death. Authority validates access and
actual mechanics. Human Throws, interruption and accepted changes retain their
existing behavior. Omens never opens an explanatory window or applies a benefit.

Use Exo 2 hierarchy and Inter values/body from the existing kit; alternate font
pairs and palette changes are outside this correction. Spacing uses 4/8/12/16px,
12px resource captions, 14px attribute captions, 16px body and 22px stat values.
Kit ink, gold, aqua, muted and error tokens retain their semantic roles. Controls
keep native keyboard focus, accessibility names, disabled styles and compact 24px icon targets. Icon glyphs are 14px and explicitly centered.
Counter values are vertically centered with their buttons. Ability rolls and the
short health action row use 28px controls with compact theme padding.
Existing loading, lost-access, save error and action-result states stay local to
their task; no extra approval UI is introduced.

## Regression and visual smoke

`tests/character_sheet_composition.gd` checks one edit entry, inline counter writes,
zero/viewer states, minimum target sizes, reserved counter value width, intrinsic
profile height, fixed action footers and absence of invented approval controls.
Run it at 326x315 (including the phone safe-area and window-border deductions), 375x313 (the phone dock body below host chrome), 412x712 and 960x888,
including Russian. The full suite also checks dirty edits, persistence boundaries,
recovery restrictions, direct Owner improvement, ordered rolls and interruption.

For isolated graphical captures set `MORK_SHEET_CAPTURE_DIR` and run this suite
without `--headless`. Review the pixels as well as the geometry: all four modifiers
fit the initial phone sheet, Omens never collides with its buttons, and both real
Rest restrictions are visible with the primary action. Scroll Character to check
profile, class actions and secondary links. Use the existing native published
Manifest journey with `--health-only` for final application verification. No local
archive import, copied Package store or new Prop is used.

Creature sheets use the same Actor window insets, compact icon component and
resource-frame style. Overview attacks call the existing attack workflow directly.
Inventory row actions remain 24px with centered 14px icons, native focus and labels.
Tab text cannot force the content wider than its viewport, including the 328px
body left after the landscape phone safe-area deduction.

Actor presentation provides the preferred or default Miniature through SDK 0.31.0.
Dragging an Owner Actor invokes placement at the dropped Scene position, creates
one Rook and links it to that existing Actor. Placement rechecks access and reports
errors through SDK feedback; no additional Actor is created.

Shared tabs are 32px high with 8px horizontal padding, so their full names fit
inside the safe-area body. Events from a retained hidden Character sheet cannot
replace the active Creature title, tabs or footer.
