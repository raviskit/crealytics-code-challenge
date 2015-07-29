require_relative 'lib/combiner'
require_relative 'lib/modifier'
require 'csv'
require 'date'

DATE_FORMAT = /\d+-\d+-\d+/
FILE_NAME_FORMAT = /\d+-\d+-\d+_[[:alpha:]]+\.txt$/

# get the latest performance data file name
def latest name
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

modified = input = latest('project_2012-07-27_2012-10-10_performancedata')
modification_factor = 1
cancellaction_factor = 0.4
modifier = Modifier.new(modification_factor, cancellaction_factor)
modifier.modify(modified, input)

puts "DONE modifying"
