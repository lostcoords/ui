require "test_helper"
require "open3"

class RailsIntegrationTest < ActiveSupport::TestCase
  test "Rails can register rendering helpers without an asset pipeline or importmap" do
    script = <<~'RUBY'
      require "tmpdir"
      require "fileutils"
      require "rails"
      require "action_controller/railtie"
      require "action_view/railtie"
      require "lostcoords/ui"
      class MinimalApp < Rails::Application
        config.eager_load = false
        config.secret_key_base = "test"
      end
      Dir.mktmpdir do |root|
        FileUtils.mkdir_p(File.join(root, "config/locales"))
        File.write(File.join(root, "config/locales/en.yml"), "en:\n  lostcoords:\n    ui:\n      copy_button:\n        label: Host copy\n")
        MinimalApp.config.root = root
        MinimalApp.initialize!
        abort "unexpected asset pipeline" if MinimalApp.config.respond_to?(:assets)
        abort "unexpected importmap" if MinimalApp.config.respond_to?(:importmap)
        abort "missing helper" unless ActionController::Base.helpers.lc_button("Save").include?("Save")
        abort "host translation overridden" unless ActionController::Base.helpers.lc_copy_button(value: "text").include?("Host copy")
        Rails.application.reloader.reload!
        abort "missing helper after reload" unless ActionController::Base.helpers.lc_icon("check").include?("<svg")
      end
    RUBY
    output, error, status = Open3.capture3("bundle", "exec", "ruby", "-Ilib", "-e", script, chdir: Lostcoords::Ui::Engine.root)
    assert status.success?, "#{output}\n#{error}"
  end
end
