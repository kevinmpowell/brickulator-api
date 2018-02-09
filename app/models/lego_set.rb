class LegoSet < ApplicationRecord
  has_many :ebay_values, dependent: :destroy
  has_many :brick_owl_values, dependent: :destroy
  has_many :bricklink_values, dependent: :destroy

  validates_presence_of :title, :number
  validates_uniqueness_of :number, scope: :number_variant

  # Could also include and preload most-recent book this way for lists if you wanted
  has_one :most_recent_brick_owl_value, -> { where(:most_recent => true) }, :class_name => 'BrickOwlValue'
  scope :last_brick_owl_value_retrieved, -> { joins(:brick_owl_values).where(:brick_owl_values => { :most_recent => true})}
  # Most recent ebay value
  has_one :most_recent_ebay_value, -> { where(:most_recent => true) }, :class_name => 'EbayValue'
  scope :last_ebay_value_retrieved, -> { joins(:ebay_values).where(:ebay_values => { :most_recent => true})}
  # Most recent bricklink value
  has_one :most_recent_bricklink_value, -> { where(:most_recent => true) }, :class_name => 'BricklinkValue'
  scope :last_bricklink_value_retrieved, -> { joins(:bricklink_values).where(:bricklink_values => { :most_recent => true})}


  after_save :set_has_variants

  def set_has_variants
    sets = LegoSet.where({number: number})
    variants = sets.find_all{ |s| s.id != id }
    if !variants.empty? || number_variant.to_i > 1
      sets.update_all( {has_variants: true} )
    end
  end

  def LegoSet.convert_currency usd_amount, currency, country, rates
    amount = usd_amount

    if currency
      # If a currency code is passed in, that trumps the conversion
      exchange_rate = rates[currency.upcase]
      amount = (usd_amount * exchange_rate).round(2) unless exchange_rate.nil?
    elsif country != 'us'
      # Otherwise if the country is something other than the US, convert to the proper currency
      currency_code = ExchangeRate::COUNTRY_CURRENCY_HASH[country.upcase.to_sym]
      exchange_rate = rates[currency_code.upcase]
      amount = (usd_amount * exchange_rate).round(2) unless exchange_rate.nil?
    end
    amount
  end

  def LegoSet.all_sets_as_object bypass_cache = false, year = Time.now.year, currency = nil, country, language
    rates = ExchangeRate.current_rates
    cache_key = "all_sets_as_json#{year}#{country}"
    cache_key = "#{cache_key}#{currency}" unless currency.nil?
    Rails.cache.fetch(cache_key, :expires_in => 15.minutes, :force => bypass_cache) do
      @lego_sets = LegoSet.all
      @id_tagged_sets = {}

      @lego_sets.includes(:most_recent_brick_owl_value, :most_recent_ebay_value, :most_recent_bricklink_value).where('year >= ? AND year < ?', year, (year.to_i + 1)).order(:year, :number).each do |set|
        # ebay = set.ebay_sales.first
        bo = set.most_recent_brick_owl_value
        e = set.most_recent_ebay_value
        bl = set.most_recent_bricklink_value
        set = set.as_json
        # if !ebay.nil?
        #   set[:ebAN] = ebay.avg_sales
        #   set[:ebLN] = ebay.low_sale
        #   set[:ebHN] = ebay.high_sale
        #   set[:ebl] = ebay.listings
        # end

        if !bo.nil?
          set[:boRA]    = bo.retrieved_at
          # set[:boPOU]   = bo.part_out_value_used                unless bo.part_out_value_used.nil?
          # set[:boPON]   = bo.part_out_value_new                 unless bo.part_out_value_new.nil?
          
          set[:boCSNLC] = bo.complete_set_new_listings_count                                              unless bo.complete_set_new_listings_count.nil?
          set[:boCSNA]  = LegoSet.convert_currency(bo.complete_set_new_avg_price, currency, country, rates)         unless bo.complete_set_new_avg_price.nil?
          set[:boCSNM]  = LegoSet.convert_currency(bo.complete_set_new_median_price, currency, country, rates)      unless bo.complete_set_new_median_price.nil?
          set[:boCSNH]  = LegoSet.convert_currency(bo.complete_set_new_high_price, currency, country, rates)        unless bo.complete_set_new_high_price.nil?
          set[:boCSNL]  = LegoSet.convert_currency(bo.complete_set_new_low_price, currency, country, rates)         unless bo.complete_set_new_low_price.nil?
          
          set[:boCSULC] = bo.complete_set_used_listings_count                                             unless bo.complete_set_used_listings_count.nil?
          set[:boCSUA]  = LegoSet.convert_currency(bo.complete_set_used_avg_price, currency, country, rates)        unless bo.complete_set_used_avg_price.nil?
          set[:boCSUM]  = LegoSet.convert_currency(bo.complete_set_used_median_price, currency, country, rates)     unless bo.complete_set_used_median_price.nil?
          set[:boCSUH]  = LegoSet.convert_currency(bo.complete_set_used_high_price, currency, country, rates)       unless bo.complete_set_used_high_price.nil?
          set[:boCSUL]  = LegoSet.convert_currency(bo.complete_set_used_low_price, currency, country, rates)        unless bo.complete_set_used_low_price.nil?

          set[:boCSCLULC]   = bo.complete_set_completed_listing_used_listings_count                                                   unless bo.complete_set_completed_listing_used_listings_count.nil?
          set[:boCSCLUA]    = LegoSet.convert_currency(bo.complete_set_completed_listing_used_avg_price, currency, country, rates)              unless bo.complete_set_completed_listing_used_avg_price.nil?
          set[:boCSCLUH]    = LegoSet.convert_currency(bo.complete_set_completed_listing_used_high_price, currency, country, rates)             unless bo.complete_set_completed_listing_used_high_price.nil?
          set[:boCSCLUL]    = LegoSet.convert_currency(bo.complete_set_completed_listing_used_low_price, currency, country, rates)              unless bo.complete_set_completed_listing_used_low_price.nil?
          
          set[:boCSCLNLC]   = bo.complete_set_completed_listing_new_listings_count                                                    unless bo.complete_set_completed_listing_new_listings_count.nil?
          set[:boCSCLNA]    = LegoSet.convert_currency(bo.complete_set_completed_listing_new_avg_price, currency, country, rates)               unless bo.complete_set_completed_listing_new_avg_price.nil?
          set[:boCSCLNH]    = LegoSet.convert_currency(bo.complete_set_completed_listing_new_high_price, currency, country, rates)              unless bo.complete_set_completed_listing_new_high_price.nil?
          set[:boCSCLNL]    = LegoSet.convert_currency(bo.complete_set_completed_listing_new_low_price, currency, country, rates)               unless bo.complete_set_completed_listing_new_low_price.nil?
          
          # set[:boMA]    = bo.total_minifigure_value_avg         unless bo.total_minifigure_value_avg.nil?
          # set[:boMM]    = bo.total_minifigure_value_median      unless bo.total_minifigure_value_median.nil?
          # set[:boMH]    = bo.total_minifigure_value_high        unless bo.total_minifigure_value_high.nil?
          # set[:boML]    = bo.total_minifigure_value_low         unless bo.total_minifigure_value_low.nil?
        end

        if !e.nil?
          set[:eRA]        = e.retrieved_at
          set[:eCSCLULC]   = e.complete_set_completed_listing_used_listings_count         unless e.complete_set_completed_listing_used_listings_count.nil?
          set[:eCSCLUA]    = LegoSet.convert_currency(e.complete_set_completed_listing_used_avg_price, currency, country, rates)              unless e.complete_set_completed_listing_used_avg_price.nil?
          set[:eCSCLUM]    = LegoSet.convert_currency(e.complete_set_completed_listing_used_median_price, currency, country, rates)           unless e.complete_set_completed_listing_used_median_price.nil?
          set[:eCSCLUH]    = LegoSet.convert_currency(e.complete_set_completed_listing_used_high_price, currency, country, rates)             unless e.complete_set_completed_listing_used_high_price.nil?
          set[:eCSCLUL]    = LegoSet.convert_currency(e.complete_set_completed_listing_used_low_price, currency, country, rates)              unless e.complete_set_completed_listing_used_low_price.nil?

          set[:eCSULC]     = e.complete_set_used_listings_count                           unless e.complete_set_used_listings_count.nil?
          set[:eCSUA]      = LegoSet.convert_currency(e.complete_set_used_avg_price, currency, country, rates)                                unless e.complete_set_used_avg_price.nil?
          set[:eCSUM]      = LegoSet.convert_currency(e.complete_set_used_median_price, currency, country, rates)                             unless e.complete_set_used_median_price.nil?
          set[:eCSUH]      = LegoSet.convert_currency(e.complete_set_used_high_price, currency, country, rates)                               unless e.complete_set_used_high_price.nil?
          set[:eCSUL]      = LegoSet.convert_currency(e.complete_set_used_low_price, currency, country, rates)                               unless e.complete_set_used_low_price.nil?
          # set[:eCSCLUTA]   = e.complete_set_completed_listing_used_time_on_market_avg     unless e.complete_set_completed_listing_used_time_on_market_avg.nil?
          # set[:eCSCLUTM]   = e.complete_set_completed_listing_used_time_on_market_median  unless e.complete_set_completed_listing_used_time_on_market_median.nil?
          # set[:eCSCLUTH]   = e.complete_set_completed_listing_used_time_on_market_high    unless e.complete_set_completed_listing_used_time_on_market_high.nil?
          # set[:eCSCLUTL]   = e.complete_set_completed_listing_used_time_on_market_low     unless e.complete_set_completed_listing_used_time_on_market_low.nil?
          
          set[:eCSCLNLC]   = e.complete_set_completed_listing_new_listings_count          unless e.complete_set_completed_listing_new_listings_count.nil?
          set[:eCSCLNA]    = LegoSet.convert_currency(e.complete_set_completed_listing_new_avg_price, currency, country, rates)               unless e.complete_set_completed_listing_new_avg_price.nil?
          set[:eCSCLNM]    = LegoSet.convert_currency(e.complete_set_completed_listing_new_median_price, currency, country, rates)            unless e.complete_set_completed_listing_new_median_price.nil?
          set[:eCSCLNH]    = LegoSet.convert_currency(e.complete_set_completed_listing_new_high_price, currency, country, rates)              unless e.complete_set_completed_listing_new_high_price.nil?
          set[:eCSCLNL]    = LegoSet.convert_currency(e.complete_set_completed_listing_new_low_price, currency, country, rates)               unless e.complete_set_completed_listing_new_low_price.nil?

          set[:eCSNLC]     = e.complete_set_new_listings_count                            unless e.complete_set_new_listings_count.nil?
          set[:eCSNA]      = LegoSet.convert_currency(e.complete_set_new_avg_price, currency, country, rates)                                 unless e.complete_set_new_avg_price.nil?
          set[:eCSNM]      = LegoSet.convert_currency(e.complete_set_new_median_price, currency, country, rates)                              unless e.complete_set_new_median_price.nil?
          set[:eCSNH]      = LegoSet.convert_currency(e.complete_set_new_high_price, currency, country, rates)                                unless e.complete_set_new_high_price.nil?
          set[:eCSNL]      = LegoSet.convert_currency(e.complete_set_new_low_price, currency, country, rates)                                 unless e.complete_set_new_low_price.nil?
          # set[:eCSCLNTA]   = e.complete_set_completed_listing_new_time_on_market_avg      unless e.complete_set_completed_listing_new_time_on_market_avg.nil?
          # set[:eCSCLNTM]   = e.complete_set_completed_listing_new_time_on_market_median   unless e.complete_set_completed_listing_new_time_on_market_median.nil?
          # set[:eCSCLNTH]   = e.complete_set_completed_listing_new_time_on_market_high     unless e.complete_set_completed_listing_new_time_on_market_high.nil?
          # set[:eCSCLNTL]   = e.complete_set_completed_listing_new_time_on_market_low      unless e.complete_set_completed_listing_new_time_on_market_low.nil?
        end

        if !bl.nil?
          set[:blRA]        = bl.retrieved_at
          set[:blCSNLC]     = bl.complete_set_new_listings_count                             unless bl.complete_set_new_listings_count.nil?
          set[:blCSNA]      = LegoSet.convert_currency(bl.complete_set_new_avg_price, currency, country, rates)                                  unless bl.complete_set_new_avg_price.nil?
          set[:blCSNM]      = LegoSet.convert_currency(bl.complete_set_new_median_price, currency, country, rates)                               unless bl.complete_set_new_median_price.nil?
          set[:blCSNH]      = LegoSet.convert_currency(bl.complete_set_new_high_price, currency, country, rates)                                 unless bl.complete_set_new_high_price.nil?
          set[:blCSNL]      = LegoSet.convert_currency(bl.complete_set_new_low_price, currency, country, rates)                                  unless bl.complete_set_new_low_price.nil?

          set[:blCSULC]     = bl.complete_set_used_listings_count                            unless bl.complete_set_used_listings_count.nil?
          set[:blCSUA]      = LegoSet.convert_currency(bl.complete_set_used_avg_price, currency, country, rates)                                 unless bl.complete_set_used_avg_price.nil?
          set[:blCSUM]      = LegoSet.convert_currency(bl.complete_set_used_median_price, currency, country, rates)                              unless bl.complete_set_used_median_price.nil?
          set[:blCSUH]      = LegoSet.convert_currency(bl.complete_set_used_high_price, currency, country, rates)                                unless bl.complete_set_used_high_price.nil?
          set[:blCSUL]      = LegoSet.convert_currency(bl.complete_set_used_low_price, currency, country, rates)                                 unless bl.complete_set_used_low_price.nil?

          set[:blCSCLULC]   = bl.complete_set_completed_listing_used_listings_count         unless bl.complete_set_completed_listing_used_listings_count.nil?
          set[:blCSCLUA]    = LegoSet.convert_currency(bl.complete_set_completed_listing_used_avg_price, currency, country, rates)              unless bl.complete_set_completed_listing_used_avg_price.nil?
          set[:blCSCLUM]    = LegoSet.convert_currency(bl.complete_set_completed_listing_used_median_price, currency, country, rates)           unless bl.complete_set_completed_listing_used_median_price.nil?
          set[:blCSCLUH]    = LegoSet.convert_currency(bl.complete_set_completed_listing_used_high_price, currency, country, rates)             unless bl.complete_set_completed_listing_used_high_price.nil?
          set[:blCSCLUL]    = LegoSet.convert_currency(bl.complete_set_completed_listing_used_low_price, currency, country, rates)              unless bl.complete_set_completed_listing_used_low_price.nil?
         
          set[:blCSCLNLC]   = bl.complete_set_completed_listing_new_listings_count          unless bl.complete_set_completed_listing_new_listings_count.nil?
          set[:blCSCLNA]    = LegoSet.convert_currency(bl.complete_set_completed_listing_new_avg_price, currency, country, rates)               unless bl.complete_set_completed_listing_new_avg_price.nil?
          set[:blCSCLNM]    = LegoSet.convert_currency(bl.complete_set_completed_listing_new_median_price, currency, country, rates)            unless bl.complete_set_completed_listing_new_median_price.nil?
          set[:blCSCLNH]    = LegoSet.convert_currency(bl.complete_set_completed_listing_new_high_price, currency, country, rates)              unless bl.complete_set_completed_listing_new_high_price.nil?
          set[:blCSCLNL]    = LegoSet.convert_currency(bl.complete_set_completed_listing_new_low_price, currency, country, rates)              unless bl.complete_set_completed_listing_new_low_price.nil?
        end

        set[:t] = set['title']
        set[:n] = set['number']
        set[:nv] = set['number_variant']
        set[:y] = set['year']
        set[:pcs] = set['part_count'].nil? ? 0 : set['part_count']

        set.delete("year")
        set.delete("part_count")
        set.delete("id")
        set.delete("number")
        set.delete("number_variant")
        set.delete("title")
        set.delete("updated_at")
        set.delete("created_at")
        set.delete("brick_owl_url")
        set.delete("brick_owl_item_id")
        set.delete("has_variants")
        set.delete("brickset_url")
        set.delete("minifig_count")
        set.delete("released")
        set.delete("packaging_type")
        set.delete("instructions_count")
        set_key = set[:n]
        if set['has_variants']
          set_key = set_key + "-" + set[:nv]
        end
        set[:k] = set_key
        @id_tagged_sets[set_key] = set
      end
      @id_tagged_sets
    end
  end
end
