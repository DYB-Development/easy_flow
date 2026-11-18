class RunViewsController < ApplicationController
  helper KeystoneUiHelper

  STEPS = {
    "review" => { state: :done, status: "answered no" },
    "gate" => { state: :done, status: "false" },
    "load_brief" => { state: :done, status: "0.3s · $0", version: nil },
    "outline" => { state: :done, status: "8.2s · $0.04", version: "v9" },
    "write_variant" => { state: :done, status: "3/3 · 41s · $0.31", version: "v22" },
    "length_terms_claims" => { state: :failed, status: "1/3 fail" },
    "human_approve" => { state: :paused, status: "waiting · expires 46h" },
    "publish_to_cms" => { state: :pending, status: "pending" }
  }.freeze

  def show
    @version = EasyFlow::Version.find(params[:id])
    @steps = @version.definition["nodes"].to_h { |node| [ node["id"], STEPS.fetch(node["id"], {}).merge(address: "/runs/#{@version.id}?step=#{node["id"]}") ] }
  end
end
