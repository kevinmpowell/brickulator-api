class LegoSetsController < ApplicationController
  before_action :set_lego_set, only: [:show]

  # GET /lego_sets
  def index
    bypass_cache = index_params[:bypass_cache].nil? ? false : index_params[:bypass_cache]
    lego_sets_object = LegoSet.all_sets_as_object(bypass_cache)
    json_response(lego_sets_object)
  end

  # GET /lego_sets/:id
  def show
    json_response(@lego_set)
  end

  private
  def set_lego_set
    @lego_set = LegoSet.find(params[:id])
  end

  def index_params
    params.permit(:bypass_cache)
  end
end
