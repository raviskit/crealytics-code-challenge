class Modifier

  KEYWORD_UNIQUE_ID = 'Keyword Unique ID'
  LAST_VALUE_WINS = ['Account ID', 'Account Name', 'Campaign', 'Ad Group', 'Keyword', 'Keyword Type', 'Subid', 'Paused', 'Max CPC', 'Keyword Unique ID', 'ACCOUNT', 'CAMPAIGN', 'BRAND', 'BRAND+CATEGORY', 'ADGROUP', 'KEYWORD']
  LAST_REAL_VALUE_WINS = ['Last Avg CPC', 'Last Avg Pos']
  INT_VALUES = ['Clicks', 'Impressions', 'ACCOUNT - Clicks', 'CAMPAIGN - Clicks', 'BRAND - Clicks', 'BRAND+CATEGORY - Clicks', 'ADGROUP - Clicks', 'KEYWORD - Clicks']
  FLOAT_VALUES = ['Avg CPC', 'CTR', 'Est EPC', 'newBid', 'Costs', 'Avg Pos']
  NUMBER_OF_COMMISSIONS = ['number of commissions']
  COMMISSION_VALUES = ['Commission Value', 'ACCOUNT - Commission Value', 'CAMPAIGN - Commission Value', 'BRAND - Commission Value', 'BRAND+CATEGORY - Commission Value', 'ADGROUP - Commission Value', 'KEYWORD - Commission Value']

  LINES_PER_FILE = 120000

  CSV_READ_OPTIONS = { col_sep: "\t", headers: :first_row }
  CSV_WRITE_OPTIONS = { col_sep: "\t", headers: :first_row, row_sep: "\r\n" }

  def initialize saleamount_factor, cancellation_factor
    @saleamount_factor = saleamount_factor
    @cancellation_factor = cancellation_factor
  end

  def modify output_file, input_file
    sorted_file = sort_by_clicks(input_file)
    input_enumerator = lazy_read(sorted_file)

    combiner = Combiner.new do |value|
      value[KEYWORD_UNIQUE_ID]
    end.combine(input_enumerator)

    merger = Enumerator.new do |yielder|
      # TODO refactor
      while true
        begin
          list_of_rows = combiner.next
          merged = combine_hashes(list_of_rows)
          yielder.yield(combine_values(merged))
        rescue StopIteration
          break
        end
      end
    end

    done = false
    file_index = 0
    file_name = output.gsub('.txt', '')
    # TODO refactor
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

  private

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

    # TODO test and refactor
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

    # TODO test and refactor
    def combine_hashes list_of_rows
      keys = []
      list_of_rows.each do |row|
        next if row.nil?
        row.headers.each do |key|
          keys << key
        end
      end
      result = {}
      keys.each do |key|
        result[key] = []
        list_of_rows.each do |row|
          result[key] << (row.nil? ? nil : row[key])
        end
      end
      result
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