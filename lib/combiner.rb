# input:
# - two enumerators returning elements sorted by their key
# - block calculating the key for each element
# - block combining two elements having the same key or a single element, if there is no partner
# output:
# - enumerator for the combined elements

class Combiner

  def initialize &key_extractor
    @key_extractor = key_extractor
  end

  def combine *enumerators
    Enumerator.new do |yielder|
      # an array of last values
      last_values = Array.new(enumerators.size)

      # done if all enumerators are nil
      done = enumerators.all?(&:nil?)

      # continue until done
      while !done

        # go through all enumerators w/ index
        last_values.each_with_index do |value, index|

          # if last value is not set, but there is a non-nil enumerator present
          if value.nil? && !enumerators[index].nil?
            begin
              # set the value to the next item
              last_values[index] = enumerators[index].next
            rescue StopIteration
              # reached the end of this enumerator
              enumerators[index] = nil
            end
          end
        end

        # done if all enumerators are nil and there are no last values
        done = enumerators.all?(&:nil?) && last_values.compact.empty?
        unless done
          min_key = get_min_key(last_values)

          # values is the size of enumerators
          values = Array.new(last_values.size)
          last_values.each_with_index do |value, index|
            if key(value) == min_key
              values[index] = value
              last_values[index] = nil
            end
          end

          # return the values
          yielder.yield(values)
        end
      end
    end
  end

  private

    def get_min_key values
      values.
        map { |value| key(value) }.
        min do |a, b|
          a.nil? ^ b.nil? ? (a.nil? ? 1 : -1) : a <=> b
        end
    end

    def key value
      @key_extractor.call(value) unless value.nil?
    end
end