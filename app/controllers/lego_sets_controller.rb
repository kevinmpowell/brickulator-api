class LegoSetsController < ApplicationController
  before_action :set_lego_set, only: [:show]

  # GET /lego_sets
  def index
    @lego_sets = LegoSet.all
    @id_tagged_sets = {}

    @lego_sets.includes(:ebay_sales).each do |set|
      ebay = set.ebay_sales.first
      set = set.as_json
      set[:ebAN] = ebay.avg_sales unless ebay.nil?
      set[:ebLN] = ebay.low_sale unless ebay.nil?
      set[:ebHN] = ebay.high_sale unless ebay.nil?
      set[:ebl] = ebay.listings unless ebay.nil?
      @id_tagged_sets[set["number"]] = set
    end
    json_response(@id_tagged_sets)
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
