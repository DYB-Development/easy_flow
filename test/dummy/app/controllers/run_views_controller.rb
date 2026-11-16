class RunViewsController < ApplicationController
  helper KeystoneUiHelper

  STEPS = {
    "load_brief" => { state: :done, status: "0.3s · $0", version: nil },
    "outline" => { state: :done, status: "8.2s · $0.04", version: "v9" },
    "write_variant" => { state: :done, status: "3/3 · 41s · $0.31", version: "v22" },
    "length_terms_claims" => { state: :failed, status: "1/3 fail" },
    "human_approve" => { state: :paused, status: "waiting · expires 46h" },
    "publish_to_cms" => { state: :pending, status: "pending" }
  }.freeze

  def show
    @version = EasyFlow::Version.find(params[:id])
    @steps = STEPS.to_h { |id, step| [ id, step.merge(address: "/runs/#{@version.id}?step=#{id}") ] }
  end
end
