source "https://rubygems.org"

# Specify your gem's dependencies in easy_flow.gemspec.
gemspec

gem "puma"

gem "sqlite3"

gem "propshaft"

# The dummy app's CSS build. Host apps bring their own; the engine ships no
# compiled stylesheet.
gem "tailwindcss-rails"

# UI components for every view the engine renders itself. The host app
# provides this at runtime; here it's for the dummy app and view tests.
gem "keystone_ui"
gem "turbo-rails"

# Drives the flow canvas in a real browser; the request tests cannot reach it.
gem "capybara"
gem "selenium-webdriver"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

gem "the_local", github: "DYB-Development/the_local"
