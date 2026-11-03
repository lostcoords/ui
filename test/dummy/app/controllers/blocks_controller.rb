class BlocksController < ApplicationController
  before_action :set_sections
  before_action :set_block, only: %i[show preview]

  def index
    @blocks = DocsBlocks.all
  end

  def show
  end

  def preview
    render layout: "block_preview"
  end

  private

  def set_sections
    @sections = Showcase.sections
  end

  def set_block
    @block = DocsBlocks.find(params[:block])
    raise ActionController::RoutingError, "Not found" unless @block
  end
end
