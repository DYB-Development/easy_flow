module EasyFlow
  class HostRoutes
    NAMES = %i[flow_path flow_runs_path flow_step_path run_path].freeze

    def initialize(routes, prefix)
      @routes = routes
      @prefix = prefix
    end

    NAMES.each do |name|
      define_method(name) { |*args, **options| @routes.public_send(:"#{@prefix}_#{name}", *args, **options) }
    end
  end
end
