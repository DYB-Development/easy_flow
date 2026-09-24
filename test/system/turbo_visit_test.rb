require "application_system_test_case"

module EasyFlow
  class TurboVisitTest < ApplicationSystemTestCase
    test "the flow editor listens for a renamed flow once however often it is visited" do
      Definition.create!(host: "dummy", slug: "intake", title: "Intake")
      visit easy_flow.manage_flows_path
      page.execute_script(<<~COUNTING)
        window.ksNamedListeners = 0
        const adding = document.addEventListener.bind(document)
        document.addEventListener = (name, listener, options) => {
          if (name === "easy_flow:flow-named") window.ksNamedListeners += 1
          adding(name, listener, options)
        }
      COUNTING

      click_on "Intake"
      find("[data-flow-heading]")
      click_on "All flows"
      click_on "Intake"
      find("[data-flow-heading]")

      assert_equal 1, page.evaluate_script("window.ksNamedListeners")
    end
  end
end
