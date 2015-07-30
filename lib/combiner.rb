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
      next_values = Array.new(enumerators.size)

      done = enumerators.all?(&:nil?)

      while !done
        next_values.each_with_index do |value, index|
          if value.nil? && !enumerators[index].nil?
            begin
              next_values[index] = enumerators[index].next
            rescue StopIteration
              enumerators[index] = nil
            end
          end
        end

        done = enumerators.all?(&:nil?) && next_values.compact.empty?

        unless done
          min_key = get_min_key(next_values)
          values = Array.new(enumerators.size)
          next_values.each_with_index do |value, index|
            if key(value) == min_key
              values[index] = value
              next_values[index] = nil
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
          a.nil? ^ b.nil? ? (a.nil? ? 1 : -1) : a <=> b
        end
    end

    def key value
      @key_extractor.call(value) unless value.nil?
    end
end