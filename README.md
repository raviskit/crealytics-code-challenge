# Crealytics code challenge

## Overview

The code is an implementation of MapReduce algorithm.  The columnar data is read from the CSV file, grouped by key, then value sequences are 'reduced' based on business logic, specific to each field type.  The results are written out to several text files (max 120,000 lines each).

## Functionality description (after refactoring)

- The code consists of three main classes: CSVInterface, Combiner and Modifier and a script which uses them to process data
- CSVInterface is responsible for reading and writing data from text files in CSV format
- The first step is to initialize a CSVInstance with the file name pattern, which then calls latest_file_path() to find the path to the latest file name (by date)
- Then a Modifier instance is created and a CSVInterface instance is passed to its modify() method to start data modification process
- The modifier uses CSVInterface instance to read the file in CSV format, sort the data by the number of clicks and write the sorted data into a separate file
- An Enumerator is created to 'lazily' read the sorted data and returned by CSV interface (input_enumerator)
- Modifier#get_combiner uses Combiner class to combine data values by key
- Modifier#get_merger uses combine_hashes to generate a hashmap of values by row headers as keys
- Modifier#get_merger further used combine_values to process each array of data values based on business rules specific to each column type (header key)
- Modifier then passes an Enumerator instance with processed data to CSVInterface#write to persist the data to output file in CSV format

## What was done

- Modifier class was extracted into a separate file
- CSVInterface class was created to handle all CSV reading/writing
- Monolithic pieces were broken down into small, digestable, self-explanatory methods
- Helper methods, assistive functionality was moved to a separate helper.rb file
- In some cases, cosmetic changes were applied to improve code readability