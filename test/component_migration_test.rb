require "test_helper"
require "open3"
require "tmpdir"

class ComponentMigrationTest < ActiveSupport::TestCase
  test "component migration preserves icon and status styling and removes eyebrow styling" do
    Dir.mktmpdir do |directory|
      path = File.join(directory, "view.html.erb")
      File.write(path, <<~ERB)
        <%= lc_card_surface do %>
          <%= lc_medallion icon: "check", tone: :success %>
          <%= lc_status_pill "Ready" %>
          <%= lc_eyebrow "Details" %>
        <% end %>
      ERB
      script = Lostcoords::Ui.root.join("script/migrate_components.py").to_s
      _, error, status = Open3.capture3("python3", script, directory)
      assert status.success?, error
      assert_includes File.read(path), "lc_eyebrow"
      _, error, status = Open3.capture3("python3", script, directory, "--write")
      assert status.success?, error
      html = ApplicationController.new.view_context.render(inline: File.read(path))
      fragment = Nokogiri::HTML.fragment(html)
      assert fragment.at_css(".lc-card.p-0 .lc-icon-badge.rounded-full.text-success")
      assert_equal "Ready", fragment.at_css(".lc-card > span.text-primary").text
      assert_equal "Details", fragment.at_css("p.text-caption").text
      assert_nil fragment.at_css(".uppercase")
      output, error, status = Open3.capture3("python3", script, directory)
      assert status.success?, error
      assert_includes output, "0 files would change"
    end
  end
end
