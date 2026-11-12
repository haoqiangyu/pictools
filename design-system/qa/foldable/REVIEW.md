# Foldable design QA — 2026-11-10

Scope: Figma design and prototype, no Flutter runtime changes.

- 23 presentation screens, 28 prototype states, 300 connections; exported ledger reports 0 connection errors and 0 text width overflow.
- Native inline preview: clicked outer-crop → inner-crop → book-crop → tabletop-crop → split-left. Each renders the same source image, 4:3 crop and 1200×900 output.
- Visual inspection covered outer home/crop, inner crop, book crop/export, tabletop crop/keyboard, left split, batch, dark and reduced-height/overflow variants. Corrected compact parameter margins, keyboard crop overlay, contextual export dimensions and redundant actions.
- Heuristic screenshot report: 2 size failures are deliberate 951×450 reduced-height fixtures and were manually inspected; 2 midtone warnings come from light neutral home/progress screens. These are documented exceptions, not a clean automated pass.
- Screen sizes and reserved regions are design samples. Platform posture detection, asynchronous processing, native keyboard, maximum text scaling and system safe areas require implementation/device testing.
- Native editable backup: `Pictools-foldable-backup.fig` (6,470,398 bytes). PNGs and native-node ledger are also retained here.
- Save verification: the version-history panel was reopened and shows the named version “Pictools 2.0 · iPhone Duo 折叠屏补充” with the 23-screen/28-state description and a recent timestamp. Earlier local-only sync warning is resolved by this later saved-version evidence. Design nodes remain present after the reconnect/refresh check.
