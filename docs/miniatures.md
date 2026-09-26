# Rookframe Miniatures

MÖRK BORG 1.0.83 ships no Miniature scenes, meshes or textures. Rookframe provides
its standard collection under Content source `fbf21a78-626e-4f35-b2ce-bd196083d9b7`.
Bent (Scum) uses `bandit`, Seth uses `goblin`, and Zukuma uses `barbarian`. Other
Creatures implicitly use `default-miniature`. Explicit Actor choices take
precedence; World-specific library overrides are copied when creating an Actor.
Clearing a library override restores the authored choice or application default.
Missing explicit choices remain visibly unavailable, rather than silently replaced.

The original authored Scum, Goblin v3 and Berserker runtime sources now live in
the Rookframe application. Original source hashes remain in this directory.
