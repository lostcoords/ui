require "test_helper"
require "open3"
require "tmpdir"

class ThemeMigrationTest < ActiveSupport::TestCase
  test "theme migration renames colors and options without matching longer names" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "view.html.erb")
      File.write(path, '<div class="bg-paper-2 text-ink-3 hover:border-accent leafy"><%= lc_icon_badge tone: :leaf %><%= lc_text tone: :subtle %></div><style>.card { --sky: green; --accent: var(--sky); color: var(--ink); --leaflet: red; }</style>')
      script = Lostcoords::Ui.root.join("script/migrate_theme.py").to_s
      _, error, status = Open3.capture3("python3", script, dir)
      assert status.success?, error
      assert_includes File.read(path), "bg-paper-2"

      _, error, status = Open3.capture3("python3", script, dir, "--write")
      assert status.success?, error
      assert_equal '<div class="bg-surface text-muted hover:border-primary leafy"><%= lc_icon_badge tone: :success %><%= lc_text tone: :muted %></div><style>.card { --primary: green;  color: var(--foreground); --leaflet: red; }</style>', File.read(path)
      output, error, status = Open3.capture3("python3", script, dir)
      assert status.success?, error
      assert_includes output, "0 files would change"
    end
  end
end
