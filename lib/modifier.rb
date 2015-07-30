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

  LINES_PER_FILE = 120000

  CSV_READ_OPTIONS = { col_sep: "\t", headers: :first_row }
  CSV_WRITE_OPTIONS = CSV_READ_OPTIONS.merge(row_sep: "\r\n")

  def initialize saleamount_factor, cancellation_factor
    @saleamount_factor = saleamount_factor
    @cancellation_factor = cancellation_factor
  end

  def modify output_file, input_file
    sorted_file = sort_by_clicks(input_file)
    input_enumerator = lazy_read(sorted_file)

    combiner = get_combiner(input_enumerator)
    merger = get_merger(combiner)

    merger_to_csv(merger, output_file)
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

    def merger_to_csv merger, output_file
      done = false
      file_index = 0
      file_name = output_file.gsub('.txt', '')

      while !done do
        CSV.open(file_name + "_#{file_index}.txt", "wb", CSV_WRITE_OPTIONS) do |csv|
          headers_written = false
          line_count = 0

          while line_count < LINES_PER_FILE
            begin
              merged = merger.next
              if !headers_written
                csv << merged.keys
                headers_written = true
                line_count +=1
              end
              csv << merged
              line_count +=1
            rescue StopIteration
              done = true
              break
            end
          end
          file_index += 1
        end
      end
    end

    # sorts by clicks
    def sort_by_clicks file
      output_file = "#{file}.sorted"
      content_as_table = read_csv(file)
      headers = content_as_table.headers
      index_of_key = headers.index('Clicks')
      sorted_content = content_as_table.sort_by { |a| -a[index_of_key].to_i }
      write_csv(sorted_content, headers, output_file)
      output_file
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

    def read_csv file
      CSV.read(file, CSV_READ_OPTIONS)
    end

    # lazily read CSV file and init an Enumerator of lines
    def lazy_read file
      Enumerator.new do |yielder|
        CSV.foreach(file, CSV_READ_OPTIONS) do |row|
          yielder.yield(row)
        end
      end
    end

    def write_csv content, headers, output
      CSV.open(output, "wb", CSV_WRITE_OPTIONS) do |csv|
        csv << headers
        content.each do |row|
          csv << row
        end
      end
    end
end