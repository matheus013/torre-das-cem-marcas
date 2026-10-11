# HUD and UI Skin

The shared skin lives in `src/presentation/ui/game_ui_skin.gd`. It uses cached
atlas regions and nine-slice textures, with nearest-neighbor filtering for the
pixel art. Gold frames, green-neutral panels and cyan focus highlights are
shared by the HUD, inventory, skills, narrative, milestones, services, shop,
settings, title screen and description tooltips.

Health, breath, cooldowns, rarity colors and gameplay data retain their existing
meaning. Inventory cells support `ui_accept` as well as mouse clicks. Icon-only
commands retain descriptive tooltips. The player menu stacks its equipment and
backpack on narrow windows and reflows the tab grid; scroll views follow focus.

Horizontal scrolling is disabled in every scroll view. Loot/backpack grids adapt
their column count to their allocated width; narrow layouts stack bestiary,
tower records and gem choices. Long descriptions wrap, while gem selectors keep
a bounded width without sizing themselves to their longest popup item. Shop and
service panels are bounded to the viewport and use vertical scrolling as needed.

Runtime resources are in `assets/ui`, outside the ignored source pack directory.
Their provenance and supplied license notices are stored alongside the atlases.
The supplied art covers all current frame/icon needs; no generated replacements
are required for this pass.

## Verification

Responsive checks cover seven widths from 480 to 1920 pixels, including panel
height, detailed stats, 30 loot types, two long support names and three mastery
choices. A deferred frame fit corrects temporary growth during text reflow.
Native captures were refreshed on 2026-10-11. Physical controller QA remains open.

```sh
godot --headless --path . --script tests/ui_skin_test.gd
godot --headless --path . --script tests/ui_no_horizontal_scroll_test.gd
sh tests/run_all.sh
godot --path . --script tools/art/ui_shots.gd
```

The screenshot harness writes 21 native-rendered captures to `art/shots/ui`:
inventory, character, skills, tower, bestiary, combat and milestone choices at
1280x720, 1920x1080 and 640x720. Physical Xbox/PlayStation controller testing
remains a manual check; automated input checks are not a substitute for it.
