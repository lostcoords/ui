require "test_helper"

module Lostcoords::Ui
  class TimeTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
      @now = Time.utc(2026, 11, 4, 12)
    end

    def render_time(value, **options) = Nokogiri::HTML.fragment(@view.lc_time(value, now: @now, **options)).at_css("time[data-slot=time]")

    test "recent times read as X shows them" do
      assert_equal "now", render_time(@now - 30.seconds).text
      assert_equal "12m", render_time(@now - 12.minutes - 40.seconds).text
      assert_equal "4h", render_time(@now - 4.hours - 59.minutes).text
      assert_equal "28 Oct", render_time(Time.utc(2026, 10, 28, 9, 30)).text
      assert_equal "4 Nov 2025", render_time(Time.utc(2025, 11, 4, 18)).text
      assert_equal "5 Nov", render_time(@now + 1.day).text
    end

    test "the full date is the title and the machine time the datetime" do
      element = render_time(Time.utc(2026, 10, 28, 9, 30), detail: "edited", class: "text-muted-foreground")
      assert_equal "2026-10-28T09:30:00Z", element["datetime"]
      assert_equal "28 October 2026, 09:30 · edited", element["title"]
      assert_equal "text-muted-foreground", element["class"]
    end

    test "a date shows its day" do
      element = render_time(Date.new(2026, 11, 4))
      assert_equal "4 Nov", element.text
      assert_equal "2026-11-04", element["datetime"]
      assert_equal "4 Nov 2026", element["title"]
    end

    test "texts and formats follow the locale" do
      I18n.with_locale(:ja) do
        assert_equal "12分", render_time(@now - 12.minutes).text
        assert_equal "2025年11月4日", render_time(Time.utc(2025, 11, 4, 18)).text
      end
      I18n.with_locale(:es) { assert_equal "ahora", render_time(@now).text }
    end

    test "lc_time needs a time" do
      assert_raises(ArgumentError) { @view.lc_time("yesterday") }
      assert_raises(ArgumentError) { @view.lc_time(nil) }
    end
  end
end
