module EasyFlow
  class Host
    BackLink = Data.define(:label, :address)

    attr_reader :name, :back_link
    attr_writer :layout, :admin_layout, :offers, :allowed_answers, :always_show_insert_buttons, :hide_step_type_codes
    attr_accessor :admin_authentication_method, :visitor_authorization_method, :refusal_method, :owner_method, :finds_flows_across_owners, :publish_note

    def initialize(name)
      @name = name.to_s
    end

    def back_link=(link)
      @back_link = link && BackLink.new(**link)
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

    def hide_step_type_codes?
      @hide_step_type_codes.present?
    end

    def offers?(step_type)
      @offers.nil? || @offers.map(&:to_s).include?(step_type.to_s)
    end
  end
end
