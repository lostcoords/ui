require "lostcoords/ui/builders"
require "lostcoords/ui/tokens"

class HomeController < ApplicationController
  def index
    @sections = Showcase.sections
  end

  def component
    @sections = Showcase.sections
    @section = @sections.find { |section| section.id.to_s == params[:component] }
    raise ActionController::RoutingError, "Not found" unless @section
  end

  def tokens
    @sections = Showcase.sections
  end

  def emoji_catalog
    render partial: "lostcoords/ui/components/emoji_picker_grid"
  end
end
