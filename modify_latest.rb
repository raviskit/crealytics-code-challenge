require_relative 'lib/combiner'
require_relative 'lib/modifier'
require_relative 'lib/csv_interface'
require_relative 'lib/helpers'
require 'csv'
require 'date'

MODIFICATION_FACTOR = 1
CANCELLATION_FACTOR = 0.4

csv_interface = CSVInterface.new('project_2012-07-27_2012-10-10_performancedata')
modifier = Modifier.new(MODIFICATION_FACTOR, CANCELLATION_FACTOR)
modifier.modify(csv_interface)

puts "DONE modifying"
