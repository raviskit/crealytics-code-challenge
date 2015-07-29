require_relative 'lib/combiner'
require_relative 'lib/modifier'
require 'csv'
require 'date'

def latest(name)
  files = Dir["#{ ENV["HOME"] }/workspace/*#{name}*.txt"]

  files.sort_by! do |file|
    last_date = /\d+-\d+-\d+_[[:alpha:]]+\.txt$/.match file
    last_date = last_date.to_s.match(/\d+-\d+-\d+/)

    date = DateTime.parse(last_date.to_s)
    date
  end

  throw RuntimeError if files.empty?

  files.last
end

# expanding standard classes
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
