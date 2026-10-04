# Russian Standards review resolution

This followup to `4b33c32bf2bb14e0b9c1c6038555daf530edb314` fixes both actionable Standards findings. An unavailable Companion Favorite returns its saved raw caption before consulting the complete readable Actor list. Present Companion and natural attack captions translate the complete `%s · %s` template before formatting their untouched Actor name and correctly localized or literal attack fragment. Symmetric English/Russian catalog entries preserve the existing visible separator.

The shared predicate is now `uses_literal_name`: custom names, changed catalogue names and unknown authored Creature attack names all use the same literal-display policy. HUD adapters retain their feature-local rendering assignment. The managed attack's `literal_name` flag exists only on the ephemeral display copy; Favorite entries/records and Actor data retain their old shapes. The existing shared melee view continues honoring its direct custom flag for earlier sheet callers. These short rendering selections do not justify another UI binding or generic renderer.

One disposable GdUnit4 case exercised actual authored HUD rows and the natural attack task through the generated public SDK and the existing substituted external locale/context/Actor boundary. It observed one native Control press for category opening, an alternate complete translation template rendering in both captions, and unchanged literal Actor names. It preserved a real normal starred dog attack's saved caption, star membership and disabled launch after Owner→Viewer and after the companion relationship ended, while SDK Actors.list still returned both Actors. It asserted the saved Favorite record stayed unchanged and both real catalogs contained the complete template. The alternate translation is a functional service substitution; it is not a change to production Russian separator text.

| Check | Cases | Time | Result |
| --- | ---: | ---: | --- |
| Review baseline | 1 | 0.778 s | Six assertion failures; zero engine errors |
| Candidate | 1 | 0.799 s | Zero failures, errors, skips, flaky cases or orphans |
| Affected retained checks | 12 | 0.705 s | Zero failures, errors, skips, flaky cases or orphans |
| Source admission | — | — | Accepted, zero diagnostics |

The retained group includes the seven localization cases, the three existing Companion row/inventory cases, and two existing shared attack-view cases. `affected-command.json` records the bounded selection. No full304 or additional profile matrix was run. The earlier three-profile Russian evidence in the parent directory remains attributed to its recorded source hashes; this followup supplies the changed-caption boundary proof and final source admission.

XML and adjacent complete logs are retained through process shutdown. Only ANSI terminal formatting was stripped; no errors were filtered. `diagnostic-fixture` preserves the first attempt's two missing external-boundary fields; the corrected baseline and candidate have zero native/script errors. The exact nine production file hashes and disposable suite hash are in `verification.json`. The suite and optional UID were removed after evidence preservation, with no external helper snapshot, retained test or wiring. Geometry, gameplay, persistence, assets, theme, SDK/dependency pins and release metadata are unchanged.
