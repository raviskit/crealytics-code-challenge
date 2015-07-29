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
      done = enumerators.all? { |enumerator| enumerator.nil? }

      # continue until done
      while !done

        # go through all last values w/ index
        last_values.each_with_index do |value, index|

          # if last value is nil, but the item at index is not nil
          if value.nil? && !enumerators[index].nil?
            begin
              # set the value to the next item
              last_values[index] = enumerators[index].next
            rescue StopIteration
              enumerators[index] = nil
            end
          end
        end

        # done if all enumerators are nil and there are no last values
        done = enumerators.all? { |enumerator| enumerator.nil? } && last_values.compact.empty?
        unless done

          # finding the min key
          min_key = get_min_key(last_values)

          values = Array.new(last_values.size)
          last_values.each_with_index do |value, index|
            if key(value) == min_key
              values[index] = value
              last_values[index] = nil
            end
          end
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
          if a.nil? && b.nil?
            0
          elsif a.nil?
            1
          elsif b.nil?
            -1
          else
            a <=> b
          end
        end
    end

    def key value
      @key_extractor.call(value) unless value.nil?
    end
end