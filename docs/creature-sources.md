# Creature content and Library sheet (RFG-347)

Content is Package-owned mechanical restatement. The approved monster authority
is in the host repository at `docs/product/mockups/monster-sheets/`, originally
pinned to `a7ef2afe711fa962c4f7cdbfc4151868358f5739`. Its existing study portraits
for Seth, the Lich and the Bone Bowyer are retained illustrations, not official
book art, Miniatures or Props. No design-system assets or tokens are changed.

## Source verification

Verified on 4 October 2026 from the official distributions:

- [MÖRK BORG Bare Bones Edition](https://jnohr.itch.io/mrk-borg-free),
  [the official PDF](https://drive.google.com/file/d/1GcysVYxEklrDCva3gSkYqXvS2vy3Kbdu/view):
  printed pp. 58–62. The downloaded pages were extracted and pages 58 and 60
  visually inspected. Seth retains HP 6, morale 7, ropy skin −d2, knife/shortbow
  d4, DR14, curse on hit **or miss**, d6-day permanence condition and all three
  bounties. The Lich retains HP 15, absent morale, barrier −d4, strike d6,
  Presence DR14 paralysis escape **each round**, nearby Power suppression,
  per-round scroll theft against its owner and all three bounties.
- [The Bone Bowyer](https://drive.google.com/file/d/1Rng4eHebeiu6z6te_HNmzCLnMGIL8fXy/view),
  official CULT single-page release, Matthew Bottiglieri; graphic design and
  art Johan Nohr. The complete downloaded page was extracted and visually
  inspected. It retains HP 25, absent morale, tanned flesh −d4, two d6 attacks
  per round, defence DR14, detection DR12 and two free shots on failed detection.
  The source leaves the detection ability unnamed. The separate bow reference
  retains repeated random retargeting until a hit and its inability to target or
  harm the Bowyer. All six commission alternatives remain reference text.
  The child-abduction commission retains its nearby-village origin and delivery
  to the Bowyer; both conditions were rechecked against the full source page on
  5 October 2026.
- Existing companions retain their previously verified rules: Ancient gore-hound
  (Bare Bones p. 47), Hawk as weapon (p. 51), dog and monkey equipment (p. 22).
  Their printed HP generation formulas and supported own tests do not become ordinary enemy tests, and absent
  morale, armor and attributes are not invented.

`logic/creature_content.gd` supplies stable rule-group IDs, classification,
reference facts and attribution. `creature_definition.gd` retains capability
profiles. Review labels Simple/Middle/Boss are not Actor statistics. Starting
loot is explicitly empty for these definitions: attack options, natural armor,
body bounties and the bow reference do not assert that a carried loot entry
exists. Live loot is independent under ADR-0024.

MÖRK BORG is © Ockult Örtmästare Games & Stockholm Kartell. This independent
System Extension uses mechanical restatements and the
[third-party license](https://morkborg.com/license/). Source names and numerical
meaning remain stable; English and Russian copy use the existing SDK translation
resources. No translated name is used as an action or entry identity.

## Authored boundary

`creature_sheet_surface.tscn` is the shared stock Godot composition. The Library
adapter opens it in the fixed Full-viewport presentation, renders immutable
starting information, and retains GM Create Actor and World Miniature-default
operations. Portrait defaults are added by RFG-353; this slice keeps published
portraits read-only. Encounter, Inventory and Appearance retain their shared
order. Source and loot Details have bounded readers and focus-return Back/Escape.

The public UI Kit's `paginated_content` measures native Controls/text lines.
It supplies bounded pages, disabled final-page controls and focus revelation;
there is no ScrollContainer, wheel/drag scrolling, HTML renderer or host-node
manipulation in this surface. Ordinary phone/tablet/desktop, language and route
permutations are manual acceptance, not retained automated matrices.

## Evidence limits

SDK source admission and focused authored-scene/creation tests observe authoring,
reference content, native Control behavior and substituted SDK boundaries.
They do not prove graphical rendering, physical input, exported installation,
World-join acquisition or real Authority persistence/replication. Native visual
acceptance requires the resulting release's public HTTPS Manifest and normal
installation/acquisition; no unpublished Package was used for application setup
or manual QA in this slice.
