require "lostcoords/ui/builders"
require "lostcoords/ui/tokens"

class HomeController < ApplicationController
  def index
    @sections = Showcase.sections
  end

  def emoji_catalog
    render partial: "lostcoords/ui/components/emoji_picker_grid"
  end
end
