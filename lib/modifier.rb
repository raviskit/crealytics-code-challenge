class Modifier

  KEYWORD_UNIQUE_ID = 'Keyword Unique ID'
  LAST_VALUE_WINS =
    " Account ID
      Account Name
      Campaign
      Ad Group
      Keyword
      Keyword Type
      Subid
      Paused
      Max CPC
      Keyword Unique ID
      ACCOUNT
      CAMPAIGN
      BRAND
      BRAND+CATEGORY
      ADGROUP
      KEYWORD".
      split("\n").map(&:strip)

  LAST_REAL_VALUE_WINS =
    " Last Avg CPC
      Last Avg Pos".
      split("\n").map(&:strip)

  INT_VALUES =
    " Clicks
      Impressions
      ACCOUNT - Clicks
      CAMPAIGN - Clicks
      BRAND - Clicks
      BRAND+CATEGORY - Clicks
      ADGROUP - Clicks
      KEYWORD - Clicks".
      split("\n").map(&:strip)

  FLOAT_VALUES =
    " Avg CPC
      CTR
      Est EPC
      newBid
      Costs
      Avg Pos".
      split("\n").map(&:strip)

  NUMBER_OF_COMMISSIONS = ['number of commissions']
  COMMISSION_VALUES =
    " Commission Value
      ACCOUNT - Commission Value
      CAMPAIGN - Commission Value
      BRAND - Commission Value
      BRAND+CATEGORY - Commission Value
      ADGROUP - Commission Value
      KEYWORD - Commission Value".
      split("\n").map(&:strip)

  def initialize saleamount_factor, cancellation_factor
    @saleamount_factor = saleamount_factor
    @cancellation_factor = cancellation_factor
  end

  def modify csv_interface
    input_enumerator = csv_interface.sort_by_clicks.lazy_read
    combiner = get_combiner(input_enumerator)
    merger = get_merger(combiner)
    csv_interface.write(merger)
  end

  private

    # combine data by key
    def get_combiner input_enumerator
      Combiner.new do |value|
        value[KEYWORD_UNIQUE_ID]
      end.combine(input_enumerator)
    end

    # merge data according to business logic
    def get_merger combiner
      Enumerator.new do |yielder|
        combiner.each do |list_of_rows|
          merged_hashes = combine_hashes(list_of_rows)
          yielder.yield(combine_values(merged_hashes))
        end
      end
    end

    def combine merged
      result = []
      merged.each do |_, hash|
        result << combine_values(hash)
      end
      result
    end

    def combine_values hash
      LAST_VALUE_WINS.each do |key|
        hash[key] = hash[key].last
      end
      LAST_REAL_VALUE_WINS.each do |key|
        hash[key] = hash[key].select {|v| !(v.nil? || v == 0 || v == '0' || v == '')}.last
      end
      INT_VALUES.each do |key|
        hash[key] = hash[key][0].to_s
      end
      FLOAT_VALUES.each do |key|
        hash[key] = hash[key][0].from_german_to_f.to_german_s
      end
      NUMBER_OF_COMMISSIONS.each do |key|
        hash[key] = (@cancellation_factor * hash[key][0].from_german_to_f).to_german_s
      end
      COMMISSION_VALUES.each do |key|
        hash[key] = (@cancellation_factor * @saleamount_factor * hash[key][0].from_german_to_f).to_german_s
      end
      hash
    end

    def combine_hashes list_of_rows
      keys = list_of_rows.compact.map(&:headers).flatten
      keys.reduce({}) do |result, key|
        result[key] = list_of_rows.map{|row| row.nil? ? nil : row[key] }
        result
      end
    end
end