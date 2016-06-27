require "HDRHistogram/version"
require "ruby_hdr_histogram"

class HDRHistogram
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
