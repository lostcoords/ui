Rails.application.configure do
  config.hosts.concat(ENV.fetch("PARCELA_SHARE_HOSTS", "").split(","))
  config.enable_reloading = true
  config.consider_all_requests_local = true
end
