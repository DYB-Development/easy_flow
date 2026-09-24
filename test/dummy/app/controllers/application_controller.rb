class ApplicationController < ActionController::Base
  def note_the_refusal(refusal)
    response.headers["X-Refusal"] = refusal.class.name
    head :forbidden
  end

  def send_a_refused_visitor_to_login(_refusal)
    redirect_to "/host-login"
  end

  def easy_flow_visitor_permitted?(flow)
    flow.present?
  end
end
