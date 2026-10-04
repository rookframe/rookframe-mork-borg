# Favorite glyph size and native state styling

Base extension: `ae521114fda16e33846a1180dcca77f704cada91`, published immutable
1.0.127 source. Stock Godot 4.7.2 Mono, public SDK 0.32.23 and runtime UI Kit
`e2a1e807d73c907bf360aa38a21a55b1773965e2`; no version or dependency changes.

Original full public127 native run45 passed both Authority and Participant cases
and complete engine shutdown with zero errors, failures or GL leaks. Its
canonical Powers captures still showed a smaller Favorite glyph than the
approved revision-8 reference. The HTML authority `mork.css` line18 specifies
24px for desktop/tablet `.mb-star`; line28 specifies21px for phone mini. Actual
authored native Favorite Buttons inherited15px in both ☆ and★ states on every
profile. Correct device flags and an empty theme variation excluded wrong
profile projection and a later replacement of an already-correct glyph role.

## Narrow correction

The Favorite now uses the already-public `TaskGlyphButton` native Theme variation
and an ordinary per-profile font-size override (24/24/21). This is the existing
UI Kit glyph-control role also used by sheet Favorite controls; no custom style
wrapper, shared Theme, token, font asset or SDK capability was introduced.

The font-only diagnostic is deliberately retained as **red**: generic Button
styles have12px content padding and raised the minimum to49×54 desktop/tablet
or46×51 phone. The existing glyph variation provides4px horizontal and2px
vertical padding, retaining the approved44×44 minimum and current input/layout
sizes. Queried native hover_pressed fallback margins are4px on each side;
minimum and actual hovered/pressed controls remain correct, so no additional
StyleBox override was warranted.

A real native unstarred hover also inherited content color instead of the
reference's muted color. Only Favorite `font_hover_color` now uses the same
existing entry-dependent Gold/muted choice. Existing normal, pressed and
hover-pressed overrides, favorite state/behavior, layout, Frame and rules remain
intact.

## One disposable authored-control case

The temporary GdUnit4 case instantiated the real Character HUD and generated
SDK facade in native SubViewports at1920×1080,1024×768 and844×390. Existing SDK
boundary substitutes supplied the Actor/context and projected entry, and a
substituted favorite-intent sink avoided a domain mutation. Actual stock mouse
motion/button input hovered the Favorite and delivered exactly one press and
favorite request per click for both ☆ and★ states. This is native authored UI
input/property acceptance with substituted domain state, **not** a new published
application or physical-device run.

- Identical published-source baseline:1case,1.192s,12failed assertions,0errors,
  skips/flaky/orphans. Six font-size assertions and six hover-color assertions
  fail. Geometry and actual native input checks otherwise pass.
- Candidate:1case,1.173s,0errors/failures/skips/flaky/orphans. It queries native
  font sizes, normal/hover/pressed/hover-pressed colors, draw mode, all StyleBox
  content margins, exact44×44 combined minimum and44-wide input rectangles.
- Existing stretched input heights remain64/52/48 for desktop/tablet/phone.
  Row sizes remain436×64,376×52 and344×48; panel sizes460×132,400×120 and360×102;
  bars1408×124,768×68 and500×48. Native control centers are actually hovered and
  clicked, rather than emitting a button signal. Only geometric float equality
  uses `is_equal_approx` for normal subpixel results such as460.0001; font sizes,
  minimum size, input counts, state and colors remain exact.
- Existing Power/special UI composition:6cases,3.187s,0errors/failures/skips/
  flaky/orphans against the final candidate.
- Public SDK source admission:accepted `source_checked`,0Diagnostics. Prepared
  export and published application runtime admission remain required before
  claiming the new visual fix complete in the actual application.

The intermediate style probe was red for the missing hover-color override and
four exact-vector assertions at subpixel geometry. It is diagnostic only; the
final identical baseline/candidate suite uses the stated tolerance and controls
acceptance. No unexpected native errors were filtered or suppressed. Saved
logs are complete runner output through engine exit with ANSI color codes alone
removed.

## Cost and cleanup

The final one-case acceptance costs1.173s; focused existing checks cost3.187s.
No retained test or matrix was added. The one temporary suite, substituted
boundary helper and any generated UIDs were removed before commit; no helper or
source snapshot was created outside the repository. XML, final logs, the two
honestly-red intermediate diagnostics and source admission remain here.
