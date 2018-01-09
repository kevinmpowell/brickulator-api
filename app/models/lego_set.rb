class LegoSet < ApplicationRecord
  has_many :ebay_sales, dependent: :destroy
  has_many :brick_owl_values, dependent: :destroy

  validates_presence_of :title, :number
  validates_uniqueness_of :number, scope: :number_variant

  # Could also include and preload most-recent book this way for lists if you wanted
  has_one :most_recent_brick_owl_value, -> { where(:most_recent => true) }, :class_name => 'BrickOwlValue'

  scope :last_brick_owl_value_retrieved, -> { joins(:brick_owl_values).where(:brick_owl_values => { :most_recent => true})}

  def LegoSet.all_sets_as_object bypass_cache = false
    Rails.cache.fetch("all_sets_as_json", :expires_in => 15.minutes, :force => bypass_cache) do
      @lego_sets = LegoSet.all
      @id_tagged_sets = {}

      @lego_sets.includes(:most_recent_brick_owl_value).where('year >= ?', 2014).order(:year, :number).each do |set|
        # ebay = set.ebay_sales.first
        bo = set.brick_owl_values.first
        set = set.as_json
        # if !ebay.nil?
        #   set[:ebAN] = ebay.avg_sales
        #   set[:ebLN] = ebay.low_sale
        #   set[:ebHN] = ebay.high_sale
        #   set[:ebl] = ebay.listings
        # end

        if !bo.nil?
          set[:boRA] = bo.retrieved_at
          set[:boPOU] = bo.part_out_value_used unless bo.part_out_value_used.nil?
          set[:boPON] = bo.part_out_value_new unless bo.part_out_value_new.nil?
          set[:boCSNLC] = bo.complete_set_new_listings_count unless bo.complete_set_new_listings_count.nil?
          set[:boCSNA] = bo.complete_set_new_avg_price unless bo.complete_set_new_avg_price.nil?
          set[:boCSNM] = bo.complete_set_new_median_price unless bo.complete_set_new_median_price.nil?
          set[:boCSNH] = bo.complete_set_new_high_price unless bo.complete_set_new_high_price.nil?
          set[:boCSNL] = bo.complete_set_new_low_price unless bo.complete_set_new_low_price.nil?
          set[:boCSULC] = bo.complete_set_used_listings_count unless bo.complete_set_used_listings_count.nil?
          set[:boCSUA] = bo.complete_set_used_avg_price unless bo.complete_set_used_avg_price.nil?
          set[:boCSUM] = bo.complete_set_used_median_price unless bo.complete_set_used_median_price.nil?
          set[:boCSUH] = bo.complete_set_used_high_price unless bo.complete_set_used_high_price.nil?
          set[:boCSUL] = bo.complete_set_used_low_price unless bo.complete_set_used_low_price.nil?
          set[:boMA] = bo.total_minifigure_value_avg unless bo.total_minifigure_value_avg.nil?
          set[:boMM] = bo.total_minifigure_value_median unless bo.total_minifigure_value_median.nil?
          set[:boMH] = bo.total_minifigure_value_high unless bo.total_minifigure_value_high.nil?
          set[:boML] = bo.total_minifigure_value_low unless bo.total_minifigure_value_low.nil?
        end

        set[:t] = set['title']
        set[:n] = set['number']
        set[:nv] = set['number_variant']
        set[:y] = set['year']
        set[:pcs] = set['part_count']

        set.delete("year")
        set.delete("part_count")
        set.delete("id")
        set.delete("number")
        set.delete("number_variant")
        set.delete("title")
        set.delete("updated_at")
        set.delete("created_at")
        set.delete("brick_owl_url")
        set.delete("brickset_url")
        set.delete("minifig_count")
        set.delete("released")
        set.delete("packaging_type")
        set.delete("instructions_count")
        set_key = set[:n]
        if !set[:nv].nil?
          set_key = set_key + "-" + set[:nv]
        end
        set[:k] = set_key
        @id_tagged_sets[set_key] = set
      end
      @id_tagged_sets
    end
  end
end
