require "application_system_test_case"

module EasyFlow
  class RadioCardSettingTest < ApplicationSystemTestCase
    def agent_flow
      @agent_flow ||= Definition.create!(host: "dummy", slug: "radio-card-setting").tap do |built|
        built.record_definition(flowing(
          "slug" => "radio-card-setting", "entry" => "write_variant",
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

    def card_layout
      page.evaluate_script(<<~JS)
        (() => {
          const cards = [...document.querySelectorAll("[data-inspector] .ks-radio-card")].map((card) => card.getBoundingClientRect())
          const row = document.querySelector("[data-inspector] [data-radio-cards]").getBoundingClientRect()
          const near = (a, b) => Math.abs(a - b) <= 1
          return {
            sideBySide: near(cards[0].top, cards[1].top),
            equalWidths: near(cards[0].width, cards[1].width),
            fillTheRow: near(cards[0].left, row.left) && near(cards[1].right, row.right)
          }
        })()
      JS
    end

    test "the settings panel sets the alias cards side by side, each half the row" do
      open_agent_settings

      assert_equal({ "sideBySide" => true, "equalWidths" => true, "fillTheRow" => true }, card_layout)
    end

    def narrow_the_panel
      page.execute_script(%(document.querySelector("[data-inspector]").style.width = "200px"))
    end

    def stacked_layout
      page.evaluate_script(<<~JS)
        (() => {
          const cards = [...document.querySelectorAll("[data-inspector] .ks-radio-card")].map((card) => card.getBoundingClientRect())
          const row = document.querySelector("[data-inspector] [data-radio-cards]").getBoundingClientRect()
          const near = (a, b) => Math.abs(a - b) <= 1
          return {
            oneCardPerRow: cards[1].top >= cards[0].bottom,
            eachFillsTheRow: cards.every((card) => near(card.left, row.left) && near(card.right, row.right))
          }
        })()
      JS
    end

    test "a settings panel too narrow for the alias cards side by side puts one card on each row" do
      open_agent_settings
      narrow_the_panel

      assert_equal({ "oneCardPerRow" => true, "eachFillsTheRow" => true }, stacked_layout)
    end

    test "the alias card an author chooses is still chosen when the flow is opened again" do
      open_agent_settings
      find("[data-inspector] .ks-radio-card", text: "candidate → v23").click
      assert_selector "[data-inspector] input[type='radio'][value='candidate']:checked", visible: :all

      open_agent_settings

      assert_selector "[data-inspector] input[type='radio'][value='candidate']:checked", visible: :all
    end

    test "opening an agent step shows each alias choice as a radio card with its hint" do
      open_agent_settings

      assert_selector "[data-inspector] .ks-radio-card", text: "candidate → v23\np 0.87 · n 240"
    end

    def choose_agent(name)
      field = find("[data-inspector] input[type='text']", match: :first)
      field.set(name)
      field.send_keys(:tab)
    end

    test "choosing another agent shows no card for an alias that agent does not have" do
      open_agent_settings
      choose_agent("copy_reviewer")
      assert_selector "[data-inspector] .ks-radio-card", text: "prod → v9"

      assert_no_selector "[data-inspector] .ks-radio-card", text: "candidate"
    end

    test "choosing an agent without the chosen alias tells the author the alias was cleared" do
      open_agent_settings
      find("[data-inspector] .ks-radio-card", text: "candidate → v23").click
      assert_selector "[data-inspector] input[type='radio'][value='candidate']:checked", visible: :all

      choose_agent("copy_reviewer")

      assert_selector "[data-inspector] [data-notice]", text: "Cleared Alias because candidate is not offered for the step's other settings."
    end
  end
end
