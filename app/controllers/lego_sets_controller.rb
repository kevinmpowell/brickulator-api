class LegoSetsController < ApplicationController
  before_action :set_lego_set, only: [:show]

  # GET /lego_sets
  def index
    @lego_sets = LegoSet.all
    @id_tagged_sets = {}

    @lego_sets.includes(:ebay_sales, :brick_owl_values).where('year >= ?', 1999).each do |set|
      ebay = set.ebay_sales.first
      bo = set.brick_owl_values.first
      set = set.as_json
      if !ebay.nil?
        set[:ebAN] = ebay.avg_sales
        set[:ebLN] = ebay.low_sale
        set[:ebHN] = ebay.high_sale
        set[:ebl] = ebay.listings
      end

      if !bo.nil?
        set[:boPOU] = bo.part_out_value_used
        set[:boPON] = bo.part_out_value_new
      end

      set.delete("updated_at")
      set.delete("created_at")
      set.delete("brick_owl_url")
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
