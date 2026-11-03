require "test_helper"
require Lostcoords::Ui.root.join("script/migrate_0_5")

class Migration05Test < ActiveSupport::TestCase
  test "renames theme colors, library names, Stimulus identifiers and options" do
    source = <<~ERB
      <div class="bg-surface hover:bg-surface-hover text-muted text-danger font-body glass squircle" data-controller="modal sheet" data-modal-target="dialog" data-action="click->row-menu#close ui-copy:error->ui-code-block#copyFailed">
        <%= lc_button "Save", size: :base %>
        <%= lc_heading "Members", size: :section %>
        <%= lc_badge "Failed", tone: :danger %>
      </div>
      <style>.card { color: var(--muted); background: var(--surface); box-shadow: var(--shadow-lg); font-family: var(--f-body), ui-sans-serif; }</style>
    ERB
    result = Migration05.rewrite(source)

    assert_includes result, "bg-muted hover:bg-accent text-muted-foreground text-destructive font-sans lc-glass lc-squircle"
    assert_includes result, 'data-controller="lc-dialog lc-sheet" data-lc-dialog-target="dialog"'
    assert_includes result, "click->lc-menu#close lc-copy:error->lc-code-block#copyFailed"
    assert_includes result, "size: :md"
    assert_includes result, "size: :heading"
    assert_includes result, "tone: :destructive"
    assert_includes result, "color: var(--muted-foreground); background: var(--muted); box-shadow: var(--lc-shadow-lg); font-family: var(--font-sans), ui-sans-serif;"
    assert Migration05.migrated?(result)
    refute Migration05.migrated?(source)
  end
end
