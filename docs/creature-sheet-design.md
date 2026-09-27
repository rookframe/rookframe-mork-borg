# Creature Actor sheet review contract

Use the unchanged Rookframe design system: Exo 2 headings and Inter body text,
17px item identity, 16px metadata, 28px stat values; package ink #010c10,
text #d9d4d1, muted #91999a, gold #f0bb32 and aqua #44e9e9.
The existing font pair is mandatory. No alternative fonts or palette are added.
Spacing uses 4/8/12/16px: 12px dock inset, 16px between sections, 16px section
padding, 12px row separation and 8px between 44px icon targets.

Creature shows public identity and one settings gear, then HP/morale/armor,
attacks and rules. Inventory and Appearance own their respective content.
Settings opens corrections with a fixed Save/Cancel footer. There is no body
Inventory shortcut, Duplicate or Place Rook button. The ordinary Actor drag
flow remains the placement affordance.

The icon-only inventory controls have native keyboard focus, named tooltips and
accessible names including the item identity. Equip uses native toggle state
and a selected frame; Unequip is the accessible action for equipped items.
Disabled buttons retain the kit disabled styling. The shared component retains
Cast/Use semantics and suitable sigil/bolt icons for Character equipment.
Empty inventory keeps its guidance and + action; read-only access disables
mutations. Saving/error feedback and Miniature loading/empty/error states reuse
the existing native workflows.

## Visual and interaction smoke

Acquire the exact published HTTPS Manifest in a fresh World. At phone 844x390
with a 375px dock, tablet 1024x768 and desktop 1920x1080, create Zukuma from
Library and inspect the live Actor sheet. Compare the actual sheet, including
its managed chrome, not only a standalone component. Verify all three tabs,
readable names and details, full 44px frames, stable section spacing, no
horizontal overflow, and no redundant action block. Inspect Creature, Inventory,
Appearance, settings and item editing. Exercise equip/unequip, the spanner,
Miniature picker and return to Appearance. Repeat phone with Russian and long
item names. Focus traversal must keep controls in the scroll viewport.

Focused GdUnit composition tests guard task hierarchy, text width, action size,
read-only behavior and signal semantics. Native published-package evidence uses
rookframe-godot's retained Rfg281MorkBorgVisualEvidence --actor-sheet-only route.
