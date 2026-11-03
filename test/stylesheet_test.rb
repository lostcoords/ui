require "test_helper"
require "open3"
require "tailwindcss/ruby"

module Lostcoords::Ui
  class StylesheetTest < ActiveSupport::TestCase
    test "a host build reaches the gem's stylesheet and scans its helpers through the engines entry" do
      Tailwindcss::Engines.bundle
      generated = Rails.root.join("app/assets/builds/tailwind/lostcoords_ui.css").read
      target = generated[/@import "([^"]+)"/, 1]

      assert Pathname(target).absolute?, generated
      assert File.file?(target), generated

      Dir.mktmpdir do |dir|
        _, error, status = Open3.capture3(Tailwindcss::Ruby.executable, "-i", Rails.root.join("app/assets/tailwind/application.css").to_s, "-o", "#{dir}/out.css")
        assert status.success?, error
        assert_includes File.read("#{dir}/out.css"), ".duration-\\[180ms\\]"
      end
    end
  end
end
