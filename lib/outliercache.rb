module SAAL
  class OutlierCache
    # By feeding values into this cache the outliers are identified. The cache
    # is conservative and only flags down values that it is sure are outliers.
    # The cache considers itself "live" when the values in the cache are all
    # within a few percent of each other and will then flag down outliers. When
    # the cache is not live all values will be considered good.

    COMP_CACHE_SIZE = 11 # Should be even so the median is well calculated

    # These are conservative settings that can be made stricted if the cache is
    # not rejecting enough values or is often not "live"
    # Sets how close the central values have to be for the cache to be "live"
    MAX_CACHE_DEVIATION = 0.05
    # Sets how off the read value can be from the cache median to be accepted
    MAX_VALUE_DEVIATION = 0.15

    def initialize
      @compcache = []
    end

    def live
      @compcache.size == COMP_CACHE_SIZE && valid_cache
    end

    def validate(value)
      ret = compare_with_cache(value)
      @compcache.shift if @compcache.size == COMP_CACHE_SIZE
      @compcache.push value
      ret
    end

    private
    def compare_with_cache(value)
      return true if !live
      @compcache.sort!
      median = @compcache[COMP_CACHE_SIZE/2]
      (value.to_f/median.to_f - 1.0).abs < MAX_VALUE_DEVIATION 
    end

    def valid_cache
      @compcache.sort!
      central = @compcache[1..(@compcache.size-2)]
      sum = central.inject(0.0){|sum,el| sum+el}
      return false if sum == 0.0
      average = sum/central.size
      central.each do |el|
        return false if (el.to_f/average.to_f - 1.0).abs > MAX_CACHE_DEVIATION
      end
      true
    end
  end
end
