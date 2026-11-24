require_relative "boot"

require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

# Live reload for the docs server only. kiln:build and tests never load it, so docs/ stays clean.
# bin/browser-test sets LIVE_RELOAD=0: every page a suite loads opens Spark's socket, and a few dozen
# of them leave the server too busy to answer the next suite's pages in time.
if Rails.env.development? && defined?(Rails::Server) && ENV["LIVE_RELOAD"] != "0"
  require "action_cable/engine"
  require "hotwire-spark"
end

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.i18n.available_locales = %i[en es ja]
  end
end
