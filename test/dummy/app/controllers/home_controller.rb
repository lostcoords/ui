require "lostcoords/ui/builders"
require "lostcoords/ui/components"
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

  def installation
    @sections = Showcase.sections
  end

  def starter
    render plain: DocsInstallation.stylesheet, content_type: "text/css"
  end

  def theming
    @sections = Showcase.sections
  end

  def palette_license
    render plain: Rails.root.join("vendor/wada/LICENSE.txt").read
  end

  def api
    render plain: DocsReference.json, content_type: "application/json"
  end

  def llms
    render plain: DocsReference.text, content_type: "text/plain"
  end

  def emoji_catalog
    render partial: "lostcoords/ui/components/emoji_picker_grid"
  end
end
