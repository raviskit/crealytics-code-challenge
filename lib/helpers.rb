DATE_FORMAT = /\d+-\d+-\d+/
FILE_NAME_FORMAT = /\d+-\d+-\d+_[[:alpha:]]+\.txt$/

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

# expanding standard classes w/ German-specific conversions
class String
  def from_german_to_f
    self.gsub(',', '.').to_f
  end
end

class Float
  def to_german_s
    self.to_s.gsub('.', ',')
  end
end