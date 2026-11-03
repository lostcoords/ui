module Lostcoords::Ui
  class Engine < ::Rails::Engine
    isolate_namespace Lostcoords::Ui

    initializer "lostcoords.ui.assets" do |app|
      app.config.assets.paths << root.join("app/javascript")
    end

    initializer "lostcoords.ui.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb")
      app.config.importmap.cache_sweepers << root.join("app/javascript")
    end

    # An isolated engine's helpers reach only its own controllers, so the host's views get them here,
    # once the autoloader can resolve them.
    config.to_prepare do
      ActionController::Base.helper Lostcoords::Ui::Engine.helpers
    end
  end
end
