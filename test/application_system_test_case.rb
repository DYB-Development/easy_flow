require "test_helper"
require "capybara/rails"
require "selenium-webdriver"

module EasyFlow
  class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
    CACHED_CHROME = Dir[File.expand_path("~/.cache/selenium/chrome/*/*/*.app/Contents/MacOS/Google Chrome for Testing")].max

    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ] do |options|
      chrome = ENV["CHROME_BIN"].presence || CACHED_CHROME
      options.binary = chrome if chrome
    end

    def canvas_for(flow)
      visit easy_flow.manage_flow_path(flow)
      assert_selector "[data-flow-canvas]"
    end

    def step_card(id)
      find("[data-step='#{id}']")
    end

    def step_ids
      all("[data-step]").map { |card| card["data-step"] }
    end

    def easy_flow
      EasyFlow::Engine.routes.url_helpers
    end
  end
end
