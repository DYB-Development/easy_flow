require "application_system_test_case"

module EasyFlow
  class BrowserResetTest < ApplicationSystemTestCase
    test "resetting the browser clears the cookies a page set" do
      visit easy_flow.manage_flows_path
      page.execute_script("document.cookie = 'left_behind=yes; path=/'")
      page.driver.reset!

      visit easy_flow.manage_flows_path

      assert_equal "", page.evaluate_script("document.cookie")
    end
  end
end
