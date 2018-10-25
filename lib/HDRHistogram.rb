require "HDRHistogram/version"
require "ruby_hdr_histogram"

class HDRHistogram
  def initialize(lowest, highest, sig, opt={})
    @multiplier = opt[:multiplier] || 1
    @unit = opt[:unit] || opt[:units]
    
    if opt[:unserialized]
      m=opt[:unserialized]
      self.unit_magnitude= m[:unit_magnitude].to_i
      self.sub_bucket_half_count_magnitude= m[:sub_bucket_half_count_magnitude].to_i
      self.sub_bucket_half_count= m[:sub_bucket_half_count].to_i
      self.sub_bucket_mask= m[:sub_bucket_mask].to_i
      self.sub_bucket_count= m[:sub_bucket_count].to_i
      self.bucket_count= m[:bucket_count].to_i
      self.min_value= m[:min_value].to_i
      self.max_value= m[:max_value].to_i
      self.normalizing_index_offset= m[:normalizing_index_offset].to_i
      self.conversion_ratio= m[:conversion_ratio].to_f
      counts_len = m[:counts_len].to_i
      self.counts_len= counts_len
      self.total_count= m[:total_count].to_i
      
      counts = m[:counts].split " "
      i=0
      shorted = 0
      counts.each do |count|
        nf="~!@#$%^&*"
        m = count.match /^([#{nf}])(\d+)$/
        if m && nf.index(m[1])
          shorted += 1
          m[2].to_i.times do
            set_raw_count(i, nf.index(m[1]))
            i+=1
          end
        else
          set_raw_count(i, count.to_i)
          i+=1
        end
      end
      if counts_len != i
        raise HDRHistogramError, "invalid serialization pattern: total count doesn't match, expected: #{counts_len}, found #{i} (diff: #{counts_len - i}), counts.count: #{counts.count}, shorted: #{shorted}"
      end
    end
  end

  def record(val)
    raw_record(val * 1/@multiplier)
  end
  def record_corrected(val, expected_interval)
    raw_record_corrected(val * 1/@multiplier, expected_interval * 1/@multiplier)
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
  def merge!(other)
    if self == other 
      raise HDRHistogramError, "can't merge histogram with itself"
    end
    if other.multiplier != multiplier
      raise HDRHistogramError, "can't merge histograms with different multipliers"
    end
    if other.unit != unit
      raise HDRHistogramError, "can't merge histograms with different units"
    end
    raw_merge other
    self
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
    pctf = @multiplier < 1 ? "%12.#{Math.log(0.001, 10).abs.ceil}f" : "%12u"
    percentiles.each do |pct|
      str << sprintf("%7.3f%% #{pctf}%s\n", pct, percentile(pct), unit)
    end
    str
  end
  
  def serialize
    attrs = [lowest_trackable_value, highest_trackable_value, unit_magnitude, significant_figures, sub_bucket_half_count_magnitude, sub_bucket_half_count, sub_bucket_mask, sub_bucket_count, bucket_count, min_value, max_value, normalizing_index_offset, ("%f" % conversion_ratio), counts_len, total_count]
    
    raw_counts = []
    numrun="~!@#$%^&*"
    
    for i in 0...counts_len do
      raw_counts << get_raw_count(i)
    end
    
    counts = []
    
    while raw_counts.length > 0 do
      num = raw_counts.shift
      n = 1
      if num < numrun.length
        while raw_counts[0] == num
          raw_counts.shift
          n+=1
        end
        if n > 1
          counts << "#{numrun[num]}#{n}"
        else
          counts << num
        end
      else
        counts << num
      end
    end
    
    "#{attrs.join " "} [#{counts.join " "} ]"
  end
  
  def self.adjusted_boundary_val(val, opt={})
    return opt ? val * 1/(opt[:multiplier] || 1) : val
  end
  private_class_method :adjusted_boundary_val
  
  def self.unserialize(str, opt={})
    regex = /^(?<lowest_trackable_value>\d+) (?<highest_trackable_value>\d+) (?<unit_magnitude>\d+) (?<significant_figures>\d+) (?<sub_bucket_half_count_magnitude>\d+) (?<sub_bucket_half_count>\d+) (?<sub_bucket_mask>\d+) (?<sub_bucket_count>\d+) (?<bucket_count>\d+) (?<min_value>\d+) (?<max_value>\d+) (?<normalizing_index_offset>\d+) (?<conversion_ratio>\S+) (?<counts_len>\d+) (?<total_count>\d+) \[(?<counts>([~!@#$%^&*]?\d+ )+)\]/
    
    m = str.match regex
    
    raise HDRHistogramError, "invalid serialization pattern" if m.nil?
    
    opt[:unserialized]=m
    
    low = m[:lowest_trackable_value].to_i * (opt[:multiplier] || 1)
    high = m[:highest_trackable_value].to_i * (opt[:multiplier] || 1)
    hdrh = self.new(low, high, m[:significant_figures].to_i, opt)
    
    return hdrh
  end
end
