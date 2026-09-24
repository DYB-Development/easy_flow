module EasyFlow
  class Engine < ::Rails::Engine
    isolate_namespace EasyFlow

    initializer "easy_flow.step_types" do |app|
      app.config.to_prepare do
        EasyFlow::Start.register
        EasyFlow::Terminal.register

        EasyFlow::Steps::Question.register
        EasyFlow::Condition.register
        EasyFlow::Switch.register

        EasyFlow.check(:unrouted_value)
        EasyFlow.check(:unfollowed_path)
        EasyFlow.check(:dead_end)
      end
    end
  end
end
