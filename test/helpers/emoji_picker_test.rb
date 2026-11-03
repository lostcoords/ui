require "test_helper"

module Lostcoords::Ui
  class EmojiPickerTest < ActiveSupport::TestCase
    test "an independently included helper translates its categories" do
      helper = Class.new { include EmojiPickerHelper }.new
      I18n.with_locale(:ja) do
        assert_equal "表情と感情", helper.lc_emoji_picker_groups.first.fetch(:name)
      end
    end
  end
end
