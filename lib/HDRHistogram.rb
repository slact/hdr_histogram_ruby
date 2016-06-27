require "HDRHistogram/version"
require "ruby_hdr_histogram"

class HDRHistogram
  def initialize(lowest, highest, sig, opt={})
    @multiplier = opt[:multiplier] || 1
    @unit = opt[:unit] || opt[:units]
  end
  
  def record(val)
    raw_record(val * 1/@multiplier)
  end
  def record_corrected(val)
    raw_record_corrected(val * 1/@multiplier)
  end
  def min
    raw_min * @multiplier
  end
  def max
    raw_max * @multiplier
  end
  def mean
    raw_mean * @multiplier
  end
  def stddev
    raw_stddev * @multiplier
  end
  def percentile(pct)
    raw_percentile(pct) * @multiplier
  end
  def merge(other)
    if other.multiplier != multiplier
      raise HDRHistogramError, "can't merge histograms with different multipliers"
    end
    if other.unit != unit
      raise HDRHistogramError, "can't merge histograms with different units"
    end
    raw_merge other
  end
  
  def to_s
    stats
  end
  
  def latency_stats
    str = "Latency Stats\n"
    str << stats([ 50.0, 75.0, 90.0, 99.0, 99.9, 99.99, 99.999, 100.0 ])
    
  end
  
  def stats(percentiles = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100])
    str = ""
    percentiles.each do |pct|
      str << sprintf("%7.3f%% %12u\n", pct, percentile(pct))
    end
    str
  end
  
end
