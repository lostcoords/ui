# Component simplification

- [x] Define the consolidated helpers and remove the old helpers.
- [x] Migrate callers, examples, class snapshots, and behavior tests.
- [x] Group icon buttons, avatar stacks, motion, and mobile dialogs into their parent documentation pages.
- [x] Update API references, migration guidance, and the component audit script.
- [x] Run tests, lint, static docs export, and live browser checks.

The public APIs retain native links, buttons, Rails forms, menu navigation, popover focus, dialog gestures, selection, and feedback behavior. Eyebrow is removed completely. Other style settings remain visible.

The final suite passes 93 tests and 10,433 assertions. Browser checks cover the migrated interactions, mobile dialog dragging, card validation, layout, and matching TOC gutters. The docs export contains 37 pages and 37 assets.

- [x] Match the TOC content gutters: 56px on each side, using a 40px column gap and 16px inner sidebar padding.
