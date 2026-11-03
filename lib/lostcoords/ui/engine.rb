module Lostcoords::Ui
  class Engine < ::Rails::Engine
    isolate_namespace Lostcoords::Ui

    initializer "lostcoords.ui.assets" do |app|
      next unless app.config.respond_to?(:assets)

      app.config.assets.paths << root.join("app/javascript")
    end

    initializer "lostcoords.ui.importmap", before: "importmap" do |app|
      next unless app.config.respond_to?(:importmap)

      app.config.importmap.paths << root.join("config/importmap.rb")
      app.config.importmap.cache_sweepers << root.join("app/javascript")
    end

    initializer "lostcoords.ui.helpers" do
      ActiveSupport.on_load(:action_view) { include Lostcoords::Ui::Helpers }
    end
  end
end
