require "pathname"
require_relative "version"

module Lostcoords::Ui
  def self.root
    @root ||= Pathname.new(File.expand_path("../../..", __dir__)).freeze
  end

  def self.view_paths
    [ root.join("app/views").to_s ]
  end

  def self.load_translations!
    paths = (Dir[root.join("config/locales/*.yml")] + I18n.load_path).uniq
    I18n.load_path = paths unless I18n.load_path == paths
  end
end
