# MÖRK BORG System Extension

This public repository is the sole source of the MÖRK BORG System Extension
Package for Rookframe. System rules, authored scenes, content and Package
releases belong here. Rookframe application capabilities belong in
[rookframe-godot](https://github.com/rookframe/rookframe-godot); shared authoring
capabilities belong in the SDK and reusable UI components in the UI Kit.

The first playable slices provide classless Character creation, editable
Character sheets and the private Creature catalogue.

## Dependencies

[`plug.gd`](plug.gd) installs both dependencies from their public repositories:

| Dependency | Exact pin | Installed path |
| --- | --- | --- |
| [Rookframe SDK](https://github.com/rookframe/rookframe-sdk) | `v0.17.1` | `addons/rookframe_sdk/` |
| [Rookframe UI Kit](https://github.com/rookframe/rookframe-ui-kit) | `9de97beeede7f9d803e6ea0abef67730cdc84692` (`v1.0.0-rc.1`) | `rookframe/ui/` |

Use gd-plug for both. Do not copy SDK/UI Kit source from local checkouts or
maintain edited consumer copies. Installed dependencies and caches are ignored
by Git. `.rookframe/authoring.lock.json` records their versions.

The Package-local `sdk/` files are generated output of the installed public SDK,
as required by its authoring contract. Regenerate them with the SDK command;
do not hand-edit them or copy them from another project.

## Fresh clone

Use Godot 4.7.2, Python 3.10+, Git, curl and the .NET 8 runtime. Replace `godot`
with your Godot executable. Matching Godot export templates are needed to build
an archive.

```sh
git clone https://github.com/rookframe/rookframe-mork-borg.git
cd rookframe-mork-borg
mkdir -p addons/gd-plug
curl -fsSL https://raw.githubusercontent.com/imjp94/gd-plug/209276d1f00d14b49b74403d9839f29598e9a8eb/addons/gd-plug/plug.gd -o addons/gd-plug/plug.gd
curl -fsSL https://raw.githubusercontent.com/imjp94/gd-plug/209276d1f00d14b49b74403d9839f29598e9a8eb/LICENSE -o addons/gd-plug/LICENSE
godot --headless --path . --script plug.gd install
python3 addons/rookframe_sdk/rookframe_authoring.py facade --project .
python3 addons/rookframe_sdk/rookframe_authoring.py check --project . --godot /path/to/godot
```

The bootstrap URLs pin gd-plug itself. Only gd-plug installs the SDK and UI Kit;
no Rookframe application checkout is needed.

Build a new archive with the installed SDK:

```sh
python3 addons/rookframe_sdk/rookframe_authoring.py build --project . --godot /path/to/godot --output build/mork-borg.rookpackage
```

Use a fresh output path for each build. Commit authored files, dependency pins,
the authoring lock and regenerated facade. Do not commit installed dependencies.

## Distribution

[GitHub releases](https://github.com/rookframe/rookframe-mork-borg/releases)
publish the Package archive and public HTTPS Manifest. The
[public Catalogue](https://catalogue.prancing-dreadnaught.com/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/1.0.33)
provides discovery. Application setup and QA use normal Manifest installation
and automatic World-join acquisition; local archive imports and copied Package
stores are not part of this workflow.
