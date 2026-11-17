require "application_system_test_case"

module EasyFlow
  class StepDetailsTest < ApplicationSystemTestCase
    def agent_flow
      @agent_flow ||= Definition.create!(host: "dummy", slug: "step-details").tap do |built|
        built.record_definition(flowing(
          "slug" => "step-details", "entry" => "write_variant",
          "nodes" => [ { "id" => "write_variant", "type" => "agent", "agent" => "copy_writer", "alias" => "prod" },
                       { "id" => "end", "type" => "terminal" } ],
          "edges" => [ { "from" => "write_variant", "to" => "end" } ]
        ))
      end
    end

    def open_agent_settings
      canvas_for(agent_flow)
      step_card("write_variant").click
      assert_selector "[data-inspector]"
    end

    test "opening an agent step shows which earlier output feeds each of its inputs" do
      open_agent_settings

      assert_selector "[data-inspector] .ks-value-list", text: "brief\nload_brief.out.brief"
    end

    test "clicking a schema's line on an agent step shows its code" do
      open_agent_settings

      find("[data-inspector] summary", text: "input_schema").click

      assert_selector "[data-inspector] .ks-code-block", text: "{brief: Brief, voice: string, angle: string, findings?: Finding[]}"
    end

    def open_the_output_schema
      open_agent_settings
      find("[data-inspector] summary", text: "output_schema").click
      assert_selector "[data-inspector] .ks-code-block", text: "headline"
    end

    def width_of(selector)
      page.evaluate_script(%(document.querySelector("#{selector}").getBoundingClientRect().width))
    end

    test "opening a schema wider than the settings panel leaves the panel 320 pixels wide" do
      open_the_output_schema

      assert_equal 320, width_of("[data-inspector]")
    end

    def scrolls_sideways?(selector)
      page.evaluate_script(<<~JS)
        (() => {
          const block = document.querySelector("#{selector}")
          const before = block.scrollLeft
          block.scrollLeft = 40
          return block.scrollWidth > block.clientWidth && block.scrollLeft > before
        })()
      JS
    end

    test "a schema wider than the settings panel scrolls sideways inside its block" do
      open_the_output_schema

      assert scrolls_sideways?("[data-inspector] details[open] .ks-code-block")
    end

    def foot_layout
      page.evaluate_script(<<~JS)
        (() => {
          const panel = document.querySelector("[data-inspector]").getBoundingClientRect()
          const link = [...document.querySelectorAll("[data-inspector] a")].find((each) => each.textContent === "Open agent").getBoundingClientRect()
          const remove = [...document.querySelectorAll("[data-inspector] button")].find((each) => each.textContent === "Delete step").getBoundingClientRect()
          return { linkAboveDelete: link.bottom <= remove.top, deleteAtFoot: Math.abs(panel.bottom - 14 - remove.bottom) <= 1 }
        })()
      JS
    end

    test "an agent step's links sit at the foot of a settings panel taller than its contents, above Delete step" do
      page.current_window.resize_to(1400, 1600)
      open_agent_settings

      assert_equal({ "linkAboveDelete" => true, "deleteAtFoot" => true }, foot_layout)
    ensure
      page.current_window.resize_to(1400, 1000)
    end

    def grid_layout
      page.evaluate_script(<<~JS)
        (() => {
          const pairs = [...document.querySelectorAll("[data-inspector] dt")].filter((label) => ["Output format", "Idempotency", "Retry"].includes(label.textContent))
          const [ format, idempotency, retry ] = pairs.map((label) => label.parentElement.getBoundingClientRect())
          const label = pairs[0].getBoundingClientRect()
          const value = pairs[0].nextElementSibling.getBoundingClientRect()
          return { twoToARow: format.top === idempotency.top && retry.top > format.top, labelAboveValue: label.bottom <= value.top }
        })()
      JS
    end

    test "an agent step's settings sit two to a row, each label above its value" do
      open_agent_settings

      assert_equal({ "twoToARow" => true, "labelAboveValue" => true }, grid_layout)
    end

    def rows_layout
      page.evaluate_script(<<~JS)
        (() => {
          const section = [...document.querySelectorAll("[data-inspector] section")].find((each) => each.textContent.startsWith("Inputs"))
          const heading = section.firstElementChild.getBoundingClientRect()
          const list = section.querySelector(".ks-value-list").getBoundingClientRect()
          const labels = [...section.querySelectorAll("dt")].map((label) => label.getBoundingClientRect())
          const gap = section.nextElementSibling.getBoundingClientRect().top - section.getBoundingClientRect().bottom
          return { headingAbove: heading.bottom <= list.top, labelsInOneColumn: labels.every((label) => label.left === labels[0].left && label.width === 90), roomUnder: gap >= 12 }
        })()
      JS
    end

    test "an agent step's Inputs sit under their heading with room below, each label in one column 90 pixels wide" do
      open_agent_settings

      assert_equal({ "headingAbove" => true, "labelsInOneColumn" => true, "roomUnder" => true }, rows_layout)
    end

    def fonts
      page.evaluate_script(<<~JS)
        (() => {
          const section = [...document.querySelectorAll("[data-inspector] section")].find((each) => each.textContent.startsWith("Inputs"))
          const monospace = (element) => getComputedStyle(element).fontFamily.includes("monospace")
          return { heading: monospace(section.firstElementChild), values: [...section.querySelectorAll("dd")].every(monospace) }
        })()
      JS
    end

    test "an agent step's Inputs show their values in a monospace font under a heading in the panel's own font" do
      open_agent_settings

      assert_equal({ "heading" => false, "values" => true }, fonts)
    end

    def on_a_phone
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
      yield
    ensure
      page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    end

    test "on a phone a step's settings panel covers the canvas from edge to edge" do
      on_a_phone do
        open_agent_settings

        assert_equal [ 0, 390 ], page.evaluate_script(%((() => { const shown = document.querySelector("[data-inspector]").getBoundingClientRect(); return [ shown.left, shown.right ] })()))
      end
    end
  end
end
