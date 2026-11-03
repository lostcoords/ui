# Component simplification

The audit is implemented. The catalog has 25 pages, 38 rendering helpers, and 50 style and support helpers, down from 30, 46 and 57 respectively.

Badge now covers status labels. Icon badge covers the former Medallion shapes and tones. Card replaces Card surface and Form card, including field contrast, avatar cutouts and validation styling. Dialog exposes mobile height options and retains the sheet gesture controller. Eyebrow is removed.

The public names now describe behavior: Toggle, Toggle group, Alert and Collapsible. Icon buttons, avatar groups, motion and mobile dialog examples appear with their parent component. All style settings stay visible.

Button class helpers and rendering helpers share their variants and primary default. Invalid options raise an error. Avatar's large size now has a distinct size. Feedback components share the same tone names.

Native links, buttons and Rails forms retain their semantics. Menu and Popover retain their separate keyboard and focus behavior. Spinner and Skeleton remain separate loading indicators.

Run `bundle exec ruby script/audit_components.rb` to check the inventory, removal of old helpers, avatar sizing, button defaults, shared tones and documentation coverage. The README contains migration guidance. Regression tests cover the former button and avatar bugs.
