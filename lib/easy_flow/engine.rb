require "keystone_ui-react"

module EasyFlow
  class Engine < ::Rails::Engine
    isolate_namespace EasyFlow

    initializer "easy_flow.tailwind" do
      next unless Gem.loaded_specs.key?("keystone_ui")

      require "keystone_ui"
      KeystoneUi.configuration.tailwind_sources << root.join("app/views/**/*.erb").to_s
      KeystoneUi.configuration.tailwind_sources << root.join("app/javascript/**/*.{js,jsx}").to_s
      KeystoneUi.configuration.tailwind_sources << root.join("app/assets/builds/easy_flow/*.js").to_s
    end

    initializer "easy_flow.step_types" do |app|
      app.config.to_prepare do
        EasyFlow::Start.register
        EasyFlow::Terminal.register

        EasyFlow::Steps::Question.register
        EasyFlow::Condition.register
        EasyFlow::Switch.register
        EasyFlow::Compare.register

        EasyFlow.check(:unrouted_value)
        EasyFlow.check(:unfollowed_path)
        EasyFlow.check(:dead_end)
      end
    end
  end
end
