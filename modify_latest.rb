require_relative 'lib/combiner'
require_relative 'lib/modifier'
require_relative 'lib/helpers'
require 'csv'
require 'date'

modified_file = input_file = latest_file_path('project_2012-07-27_2012-10-10_performancedata')
modification_factor = 1
cancellaction_factor = 0.4
modifier = Modifier.new(modification_factor, cancellaction_factor)
modifier.modify(modified_file, input_file)

puts "DONE modifying"
