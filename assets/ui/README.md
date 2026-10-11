# Runtime UI Assets

These atlases contain only the frame and icon regions used by the game. The
original packs in `assets/new/ui` are left unchanged and are not required by
release builds.

- `dark_ages.png`: Dark Ages UI v1.0 by Hypnobius. See `DarkAges-LICENSE.txt`.
- `medieval_icons.png`: Free Medieval Fantasy UI Pack by Kibyra. See
  `MedievalIcons-README.txt`.

The supplied licenses allow use in games, including commercial projects. They
do not permit selling or redistributing the source packs as asset packs. These
files are included as game resources, not as a standalone asset distribution.
Keep the accompanying license notices with this directory.

Regenerate the runtime atlases from the locally supplied packs:

```sh
godot --headless --path . --script tools/art/import_ui_assets.gd
godot --headless --path . --editor --quit
```
