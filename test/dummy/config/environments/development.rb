Rails.application.configure do
  config.hosts.concat(ENV.fetch("PARCELA_SHARE_HOSTS", "").split(","))
  config.enable_reloading = true
  config.consider_all_requests_local = true

  # The gem's helpers and parts are required once at boot, outside the autoloader. Reload them
  # when they change so a running docs server shows library edits without a restart.
  library = Lostcoords::Ui::Engine.root
  library_files = -> { Dir[library.join("app/helpers/lostcoords/ui/*.rb"), library.join("lib/lostcoords/ui/{parts,form_builder}.rb")] }
  watcher = ActiveSupport::FileUpdateChecker.new(library_files.call) do
    silence_warnings { library_files.call.each { |path| load path } }
  end
  config.to_prepare { watcher.execute_if_updated }
end
