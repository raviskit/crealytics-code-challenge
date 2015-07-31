class CSVInterface

  DATE_FORMAT = /\d+-\d+-\d+/
  FILE_NAME_FORMAT = /\d+-\d+-\d+_[[:alpha:]]+\.txt$/

  CSV_READ_OPTIONS = { col_sep: "\t", headers: :first_row }
  CSV_WRITE_OPTIONS = CSV_READ_OPTIONS.merge(row_sep: "\r\n")

  LINES_PER_FILE = 120_000

  def initialize input_file
    @input_filename = latest_file_path(input_file)
    @output_filename = @input_filename.gsub('.txt', '')
  end

  def sort_by_clicks
    output_file = "#{ @input_filename }.sorted"
    content_as_table = read_csv(@input_filename)
    headers = content_as_table.headers
    index_of_key = headers.index('Clicks')
    sorted_content = content_as_table.sort_by { |a| -a[index_of_key].to_i }
    write_sorted(sorted_content, headers, output_file)
    @input_filename = output_file
    self
  end

  def lazy_read
    Enumerator.new do |yielder|
      CSV.foreach(@input_filename, CSV_READ_OPTIONS) do |row|
        yielder.yield(row)
      end
    end
  end

  def write merger
    done = false
    file_index = 0

    while !done do
      CSV.open(@output_filename + "_#{ file_index }.txt", "wb", CSV_WRITE_OPTIONS) do |csv|
        begin
          merged = merger.next
          csv << merged.keys
          csv << merged
          line_count = 2

          while line_count < LINES_PER_FILE
            merged = merger.next
            csv << merged
            line_count += 1
          end

        rescue StopIteration
          done = true
        end
        file_index += 1
      end
    end
  end

  private

    # get the latest performance data file path
    def latest_file_path name
      files = Dir["#{ ENV["HOME"] }/workspace/*#{ name }*.txt"]
      throw RuntimeError if files.empty?

      files.sort_by! do |file_name|
        file_match_data = FILE_NAME_FORMAT.match file_name
        date_match_data = file_match_data.to_s.match DATE_FORMAT
        DateTime.parse(date_match_data.to_s)
      end
      files.last
    end

    def read_csv file
      CSV.read(file, CSV_READ_OPTIONS)
    end

    def write_sorted content, headers, output
      CSV.open(output, "wb", CSV_WRITE_OPTIONS) do |csv|
        csv << headers
        content.each do |row|
          csv << row
        end
      end
    end
end