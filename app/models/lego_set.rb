class LegoSet < ApplicationRecord
  has_many :ebay_sales, dependent: :destroy
  has_many :brick_owl_values, dependent: :destroy

  validates_presence_of :title, :number
  validates_uniqueness_of :number, scope: :number_variant

  def LegoSet.all_sets_as_object
    Rails.cache.fetch("all_sets_as_json", :expires_in => 15.minutes) do
      @lego_sets = LegoSet.all
      @id_tagged_sets = {}

      @lego_sets.includes(:ebay_sales, :brick_owl_values).where('year >= ?', 2014).order(:year, :number).each do |set|
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
