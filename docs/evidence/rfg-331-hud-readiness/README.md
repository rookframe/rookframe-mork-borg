# Preserve confirmed HUD state during incomplete World updates

Base extension: `46977f51024bb91847ad90b9f4599b34cefcf8a8`. Stock Godot
4.7.2 Mono, public SDK 0.32.23 and runtime UI Kit
`e2a1e807d73c907bf360aa38a21a55b1773965e2`; unchanged pins and version.

The actual public125 native Ability → Dice rail cancel → Attacks handoff closes
the panel while a complete native World update is arriving. The corresponding
host evidence is `docs/evidence/rfg-331-session-readiness` in rookframe-godot:
raw authenticated Session/Participant and connected peer remain current while
SDK reads are legitimately `not_ready`. The host fix preserves Session
classification; this Package fix preserves the last confirmed Actor and opened
panel for `not_ready` / `operation_in_progress`. With no confirmed Actor, the
HUD remains hidden. All other invalid context, access, Actor lifetime and schema
branches retain immediate hiding. Complete-state notifications refresh fields
and entries normally. Retryable preparation refusals produce no misleading
permanent error feedback.

## Disposable acceptance

The disposable GdUnit4 suite instantiated the real authored Character HUD,
public theme and generated SDK facade in a native SubViewport. Stock
InputEventMouseMotion/InputEventMouseButton dispatch pressed Attacks exactly
once. The domain-read results and WorldChanged signals were **substituted at the
SDK boundary**: this proves authored-control behavior, not real network timing,
public Package runtime admission or physical-device input. No checkbox/category
signal emission substituted for the actual native button press.

- Baseline identical 13-case suite: 1.319 s, 4 failed cases / 16 failed
  assertions, 0 errors. Both retryable HUD-context codes and both retryable Actor
  reads lose their opened panel and confirmed Actor.
- Candidate: 13 cases, 1.272 s, 0 errors, failures, skipped, flaky or orphan
  cases. Retryable context/read responses preserve the panel and Actor;
  initial unconfirmed retryable responses keep HUD hidden. Later complete
  WorldChanged refreshes name, HP and Strength entries. Confirmed Actor clear,
  Viewer access, access_denied, not_found, wrong schema, authority_unavailable
  and session_ended hide immediately.
- Existing character/creature sheet composition regression checks: 13 cases,
  72.388 s, zero errors/failures/skips/flaky/orphans.
- Public SDK source check: `source_checked`, accepted, zero Diagnostics.
  This is source-only admission; prepared exports and application runtime
  admission remain required for the next reviewed immutable release.

Both temporary GdUnit scripts and any generated UIDs were removed before
commit. Useful XML and complete runner logs are retained here (ANSI colors
alone removed); no retained suite or matrix was added. Public125 acquired
payloads remained unchanged throughout. Combined native handoff acceptance
waits for the reviewed host change and officially published next Package.
