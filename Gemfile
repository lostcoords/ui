source "https://rubygems.org"

gemspec

gem "rails", ">= 8.0"
gem "importmap-rails", ">= 2.0"
gem "propshaft"
gem "puma"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 4.4"
gem "turbo-rails"

# Static export of the docs app (test/dummy) to docs/
gem "kiln", "~> 0.1.3"

group :development do
  # Live reload for the docs server (bin/rails server)
  gem "hotwire-spark", require: false
end

group :development, :test do
  gem "bundler-audit", require: false
  gem "rubocop-rails-omakase", require: false
end
