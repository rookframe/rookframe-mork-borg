# MÖRK BORG character sheet

RFG-336 supersedes the earlier compact sheet. The full-viewport Surface has
Character, Powers, Inventory, Journal and Appearance chapters. Use the unchanged
Rookframe design authority and public UI Kit with ordinary Godot Controls,
Resources and signals.

The persistent core shows identity, a 4:5 portrait, HP, Power uses, Omens,
four played modifiers, the ready weapon and protection. Phone landscape uses
compact weapon/protection disclosures and a Section selector. Details and
collection pages are bounded and measured, without page or collection scrolling.
Q/E changes chapters; Back/Escape returns focus. Chapter, page and ready weapon
are local per Actor for the running World Application, resetting on restart.

Edit sheet retains one shared character-field draft across chapters and Details.
Untouched fields refresh; changed fields retain their local text. Save writes
changed fields only; Cancel presents latest Actor values. Removed/replaced entries
invalidate obsolete fields. Inventory commits independently and survives Save
and Cancel. Class text never changes class identity; curated mechanics stay read-only.

Sheet actions use local Window Dice, accepted Rolls and Action Log reports.
Attack and Damage are separate. First accepted Damage consumes matching Attack
context, retaining its weapon formula after ammunition consumption. Own costs
and supported own effects remain; targets are handled manually. Closing preserves
a running Roll, while abandoning its workflow cancels an unfinished Roll.

Rest rolls d4 or d6 recovery capped at maximum HP, with eligibility at the table.
Morning Power uses and laboratory brewing are independent Overview actions.
Improvement follows the implemented ordered procedure; leaving unfinished ends
it, retaining accepted changes and leaving remaining steps for manual resolution.

Broken incidents belong to shared Actor data. A zero-HP incident rolls once and
retains injury, duration and future recovery HP. Next round/hour and undo record
game time. Recovery applies stored HP once when due; treatment stops hemorrhage
without healing. Test, Attack and Cast are restricted while unable to act or dead.
Retained injuries add no invented modifiers.

Portrait and preferred Miniature changes update immediately through SDK domain
operations. Existing Rooks retain their Miniatures. Journal is a local placeholder
with disposable editor text only: leaving or rebuilding the editor discards it;
no text is retained in navigation, Actor, World, reconnect state or files.
Preferred Miniature selection uses the existing full-screen browser; the mockup's
Miniature modal was superseded by the user on 2 October 2026. Viewer access keeps references readable and disables writes.
QA uses public HTTPS Manifests and normal installation/World-join acquisition.


In the full sheet, accepted Improvement results remain visible until Continue.
Continue opens the unrolled Debris or Abilities phase; its Roll action requests
the next Throw. HP increases and Silver have their own Roll actions. Completed HP, debris, Silver,
scroll and ability results retain their individual faces and before/after values.
Back offers Continue procedure or End procedure; End preserves accepted changes
and does not create a resumable procedure. Existing compact recovery controls
retain their prior automatic sequence. Due Broken recovery is capped at the
current maximum HP; the incident keeps the original die result.

Details use one bounded authored body and a public pager in their fixed footer.
Nested references retain page history; native editor focus returns after World
refresh. Escape cancels the shared sheet draft; Back retains it. Save validates
through the same character correction boundary used by the inline resource rows.
