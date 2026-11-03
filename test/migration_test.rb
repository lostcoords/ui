require "test_helper"
require "open3"
require "tmpdir"

class MigrationTest < ActiveSupport::TestCase
  test "Ruby and ERB calls migrate without changing literal text or CSS classes" do
    Dir.mktmpdir do |directory|
      ruby = File.join(directory, "helper.rb")
      erb = File.join(directory, "view.html.erb")
      File.write(ruby, <<~'RUBY')
        def button_variants
          super
        end
        ui_button "tw", class: "heroicon"
        send(:button_class)
        message = "保存"; ui_button(message)
        %i[ui_button button_class]
      RUBY
      File.write(erb, '<p class="heroicon">button_class 日本語</p><%= ui_button "tw" %><%# ui_button %>')
      _, error, status = migrate(directory, "--write")
      assert status.success?, error
      assert_equal <<~'RUBY', File.read(ruby)
        def lc_button_variants
          super
        end
        lc_button "tw", class: "heroicon"
        send(:lc_button_class)
        message = "保存"; lc_button(message)
        %i[lc_button lc_button_class]
      RUBY
      assert_equal '<p class="heroicon">button_class 日本語</p><%= lc_button "tw" %><%# ui_button %>', File.read(erb)
      output, error, status = migrate(directory)
      assert status.success?, error
      assert_includes output, "0 files would change"
    end
  end

  test "a template rename collision prevents every write" do
    Dir.mktmpdir do |directory|
      helper = File.join(directory, "a.rb")
      File.write(helper, "ui_button 'Save'\n")
      File.write(File.join(directory, "_ui_dialog.html.erb"), "Old template")
      File.write(File.join(directory, "_lc_dialog.html.erb"), "Existing template")
      _, error, status = migrate(directory, "--write")
      refute status.success?
      assert_includes error, "Refusing to overwrite"
      assert_equal "ui_button 'Save'\n", File.read(helper)
      assert_equal "Existing template", File.read(File.join(directory, "_lc_dialog.html.erb"))
    end
  end

  test "keyword arguments and strict ERB locals keep their names" do
    Dir.mktmpdir do |directory|
      ruby = File.join(directory, "helper.rb")
      erb = File.join(directory, "_picker.html.erb")
      File.write(ruby, "def picker(popover_class: nil)\n  [popover_class, self.popover_class]\nend\n")
      File.write(erb, '<%# locals: (popover_class: nil) %>日本語<div class="<%= popover_class %>"><%== ui_button "Save" %><%= yield %></div>')
      _, error, status = migrate(directory, "--write")
      assert status.success?, error
      assert_equal "def picker(popover_class: nil)\n  [popover_class, self.lc_popover_class]\nend\n", File.read(ruby)
      assert_equal '<%# locals: (popover_class: nil) %>日本語<div class="<%= popover_class %>"><%== lc_button "Save" %><%= yield %></div>', File.read(erb)
    end
  end

  private

  def migrate(directory, *arguments)
    Open3.capture3(RbConfig.ruby, Lostcoords::Ui.root.join("script/migrate_helpers.rb").to_s, directory, *arguments)
  end
end
