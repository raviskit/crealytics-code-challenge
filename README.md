# Crealytics code challenge

## Functionality description

- Provided code consists of two main classes: Combiner and Modifier and a script which uses them to process data
- The first step is to identify the latest file name (by date) which matches a specified pattern -- latest_file_path()
- A Modifier instance reads the file in CSV format, sorts the data by the number of clicks and writes the sorted data into a separate file
- An Enumerator is created to 'lazily' read the sorted data (input_enumerator)
- Modifier#get_combiner uses Combiner class to combine data values by key
- Modifier#get_merger uses combine_hashes to generate a hashmap of values by row headers as keys
- Modifier#get_merger further used combine_values to process each array of data values based on business rules specific to each column type (header key)
- Modifier#merger_to_csv uses passed Enumerator instance to write processed data to output file in CSV format

## What was done

- Modifier class was extracted into a separate file
- Monolithic pieces were broken down into small, digestable, self-explanatory methods
- Helper methods, assistive functionality was moved to a separate helper.rb file
- In some cases, cosmetic changes were applied to improve code readability