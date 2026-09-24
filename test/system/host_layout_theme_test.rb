require "application_system_test_case"

module EasyFlow
  class HostLayoutThemeTest < ApplicationSystemTestCase
    test "choosing dark mode puts the host layout's page on the palette's darkest surface" do
      visit easy_flow.manage_flows_path
      page.execute_script(%(document.documentElement.dataset.theme = "dark"))

      assert_equal color_of_variable("--color-surface-950"), page.evaluate_script("getComputedStyle(document.body).backgroundColor")
    end

    private

    def color_of_variable(name)
      page.evaluate_script(<<~JS)
        (() => {
          const probe = document.createElement("div")
          probe.style.backgroundColor = "var(#{name})"
          document.body.appendChild(probe)
          const color = getComputedStyle(probe).backgroundColor
          probe.remove()
          return color
        })()
      JS
    end
  end
end
