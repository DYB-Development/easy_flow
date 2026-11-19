require "test_helper"
require "capybara/rails"
require "selenium-webdriver"
require "capybara/selenium/driver"

# Chrome 158 refuses the "*" origin Capybara 3.40 clears on reset (teamcapybara/capybara#2865); remove once a released Capybara stops sending it.
module ChromeResetWithoutWildcard
  private

  def execute_cdp(cmd, params = {})
    return super unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    super("Network.clearBrowserCookies")
    super(cmd, { origin: Capybara.current_session.server.base_url, storageTypes: params[:storageTypes] })
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeResetWithoutWildcard)

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
  end
end
