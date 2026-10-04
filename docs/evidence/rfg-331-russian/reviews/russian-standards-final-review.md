## Standards

Bounded recheck of `4b33c32bf2bb14e0b9c1c6038555daf530edb314...1237f08c6ebb6ea555eddd3d1452cf819010222d` against the four initial points: **zero unresolved findings**.

- The **P2 saved-caption breach is resolved**: `ui/hud_companions.gd::_title` immediately returns the saved literal caption when `present=false`, before examining current Actors or inventory.
- The **P3 complete-template breach is resolved**: Companion and natural attack captions translate `%s · %s` before formatting. Both English and Russian catalogs declare the template, while Actor names remain literal.
- The **possible Duplicated Code smell is resolved sufficiently**: `logic/actor_favorites.gd::uses_literal_name` centralizes custom, changed-default and unknown-Creature name policy. The adapters' remaining single rendering choices are ordinary feature-local presentation, consistent with the repository's SDK/UI guidance; another binding abstraction is unnecessary.
- The **possible Mysterious Name smell is resolved**: `uses_literal_name` describes the actual display decision, including the conservative unknown-source fallback. The managed attack carries its `literal_name` decision only in its existing ephemeral display copy; the shared melee view's direct custom check preserves established sheet callers.

The scoped review-resolution evidence reports zero candidate/affected-check failures and zero source-admission diagnostics; the earlier three-profile evidence remains explicitly attributed to its earlier source. This recheck ran no tests, changed no repository files, and made no broader acceptance claim.
