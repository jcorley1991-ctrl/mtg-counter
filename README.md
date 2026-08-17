# MTG Counter App — Stage 1 Scaffold

This repository scaffold implements the **approved Stage 1 table shell** for the iOS + Android MTG life/counter application.

## Locked product direction represented here

- 2–6 players
- Seat-aware / multidirectional player panels
- Black negative space
- Large rounded fantasy-style player panels
- Life remains the dominant visual element
- Poison is permanently visible on each panel
- Commander damage (CMD) is permanently visible on each panel
- Compact shared utility bar
- Per-player settings access
- Source-specific commander-damage data model preserved for later implementation

## Stage boundary

Implemented now:

- Responsive geometry for 2, 3, 4, 5, and 6 players
- Seat rotations
- Life +/- interaction
- Basic undo
- Player count switcher
- Reset confirmation
- Visual placeholders for poison, CMD, theme, dice, and settings

Intentionally deferred according to the approved implementation order:

- Poison editing
- Commander-damage source sheet and matrix
- Partner commander configuration
- Token tracker
- Secondary counters
- Monarch / Initiative / Day-Night / City's Blessing
- Final fantasy artwork/theme system
- Persistence

The visual placeholders **do not supersede the approved fantasy mockups**. The approved fantasy mockups from the design session remain the visual authority. A reference manifest is kept under `docs/reference/`; final image assets will be imported during the approved artwork/theme stage.

## Stack

Working implementation stack: **Flutter / Dart**.

Flutter is being used because the app requires one iOS + Android codebase and unusually custom, rotated, responsive table UI. Final product branding, package identifier, and app-store signing identifiers remain unresolved.

## Local setup

1. Install the stable Flutter SDK.
2. Run `./tool/bootstrap_platforms.sh` once to generate the Android and iOS platform shells.
3. Run `flutter pub get`.
4. Run `flutter run`.

The bootstrap script deliberately uses a temporary development organization identifier (`dev.local.mtgcounter`). It is **not** the final bundle/application ID.
