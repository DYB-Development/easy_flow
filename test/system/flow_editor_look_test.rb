require "application_system_test_case"

module EasyFlow
  class FlowEditorLookTest < ApplicationSystemTestCase
    def flow
      @flow ||= Definition.create!(host: "dummy", slug: "editor-look").tap do |built|
        built.record_definition(flowing(
          "slug" => "editor-look", "entry" => "first",
          "nodes" => [ { "id" => "first", "type" => "question", "question" => "First",
                         "answers" => [ { "value" => "yes" } ] } ],
          "edges" => []
        ))
      end
    end

    test "a palette's accent color reaches the flow panel's publish button" do
      canvas_for(flow)
      page.execute_script(%(document.documentElement.style.setProperty("--color-accent-600", "rgb(1, 2, 3)")))
      find("[data-open-panel]").click

      assert_equal "rgb(1, 2, 3)", background_of(find("[data-publish]"))
    end

    test "choosing dark mode sets the flow panel on keystone's dark panel color" do
      canvas_for(flow)
      find("[data-open-panel]").click
      page.execute_script(%(document.documentElement.dataset.theme = "dark"))

      assert_equal color_of_variable("--color-zinc-900"), background_of(find("[data-builder-panel]"))
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

    def background_of(element)
      page.evaluate_script("getComputedStyle(arguments[0]).backgroundColor", element)
    end
  end
end
