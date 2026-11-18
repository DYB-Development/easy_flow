module EasyFlow
  class Host
    BackLink = Data.define(:label, :address)
    Button = Data.define(:label, :address)
    Tab = Data.define(:label, :count, :content) do
      def initialize(label:, content:, count: nil)
        super
      end
    end

    attr_reader :name, :back_link
    attr_writer :layout, :admin_layout, :offers, :allowed_answers, :always_show_insert_buttons, :hide_step_type_codes, :marks_ends, :on_publish, :canvas_direction, :editor_buttons, :drawer_tabs
    attr_accessor :admin_authentication_method, :visitor_authorization_method, :refusal_method, :owner_method, :finds_flows_across_owners, :publish_note

    def initialize(name)
      @name = name.to_s
    end

    def back_link=(link)
      @back_link = link.respond_to?(:call) ? link : link && BackLink.new(**link)
    end

    def back_link_for(flow)
      @back_link.respond_to?(:call) ? BackLink.new(**@back_link.call(flow)) : @back_link
    end

    def editor_buttons_for(flow)
      listed = @editor_buttons.respond_to?(:call) ? @editor_buttons.call(flow) : @editor_buttons
      Array(listed).map { |button| Button.new(**button) }
    end

    def drawer_tabs_for(flow)
      listed = @drawer_tabs.respond_to?(:call) ? @drawer_tabs.call(flow) : @drawer_tabs
      Array(listed).map { |tab| Tab.new(**tab) }
    end

    def setting_explanations=(explanations)
      explained = explanations.to_h.deep_stringify_keys
      raise ArgumentError, "an explanation must be text, and a list entry's setting is named like answers.weight" unless explained.values.flat_map(&:values).all? { |text| text.nil? || text.is_a?(String) }

      @setting_explanations = explained
    end

    def layout
      @layout || "easy_flow/application"
    end

    def admin_layout
      @admin_layout || "application"
    end

    def flows
      Definition.where(host: name)
    end

    def set_up?
      true
    end

    def answers_allowed(step, answers)
      @allowed_answers&.call(step, answers)
    end

    def always_show_insert_buttons?
      @always_show_insert_buttons.present?
    end

    def canvas_direction
      @canvas_direction || :top_to_bottom
    end

    def marks_ends?
      @marks_ends.present?
    end

    def hide_step_type_codes?
      @hide_step_type_codes.present?
    end

    def step_groups=(groups)
      @step_groups = groups.to_h { |heading, step_types| [ heading.to_s, step_types.map(&:to_s) ] }
    end

    def step_groups
      @step_groups || {}
    end

    def summaries=(summaries)
      @summaries = summaries.to_h.transform_keys(&:to_s)
    end

    def summary_of(node)
      @summaries.to_h[node.type.to_s]&.call(node).presence
    end

    def explanation_for(step_type, setting)
      @setting_explanations.to_h.dig(step_type.to_s, setting.to_s).presence
    end

    def published(flow)
      @on_publish&.call(flow)
    end

    def offers?(step_type)
      @offers.nil? || @offers.map(&:to_s).include?(step_type.to_s)
    end
  end
end
