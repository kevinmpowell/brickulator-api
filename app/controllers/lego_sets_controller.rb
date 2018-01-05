class LegoSetsController < ApplicationController
  before_action :set_lego_set, only: [:show]

  # GET /lego_sets
  def index
    lego_sets_object = LegoSet.all_sets_as_object
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
end
