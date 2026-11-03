require "test_helper"
require "lostcoords/ui/tokens"
require "tailwindcss/ruby"

module Lostcoords::Ui
  class TokensTest < ActiveSupport::TestCase
    test "the token list is exactly what the gem's CSS and JS read from the host" do
      derived = Lostcoords::Ui::Tokens.derive(Rails.root.join("app/assets/tailwind/application.css"), tailwindcss: Tailwindcss::Ruby.executable)

      assert_equal Lostcoords::Ui::TOKENS.sort, derived
    end
  end
end
