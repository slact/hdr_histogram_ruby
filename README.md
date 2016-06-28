#Ruby HdrHistogram Library

## Overview
HdrHistogram is an algorithm designed for recording histograms of value measurements with configurable precision. Value precision is expressed as the number of significant digits, providing control over value quantization and resolution whilst maintaining a fixed cost in both space and time.
More information can be found on the [HdrHistogram site](http://hdrhistogram.org/) (which much of the text in this README paraphrases).  This library wraps the [C port](https://github.com/HdrHistogram/HdrHistogram_c).


## Installation

```shell
  gem install HDRHistogram
```

## Usage

### Examples

#### Basic usage
```ruby

require "HDRHistogram"

hdr = HDRHistogram.new(1,1000000,3)

i=10
while i != 1000000 do
  hdr.record(i)
  i+=10
end

p50 = hdr.percentile(50)
#p50 == 500223
```

#### Multipliers and units
While hdr_histogram internally can represent only integers between 1 and an integer upper bound, the Ruby HDRHistogram can be initialized with a multiplier to adjust the recorded values, as well as a named unit for the values for output:
```ruby
#record milliseconds with 3 digits past the decimal
hdr = HDRHistogram.new(0.001,1000, 3, multiplier: 0.001, unit: :ms)

i=0.001
while i <= 1000 do
  hdr.record(i)
  i += 0.010
end

puts hdr.stats
#  10.000%      100.031ms
#  20.000%      200.063ms
#  30.000%      300.031ms
#  40.000%      400.127ms
#  50.000%      500.223ms
#  60.000%      600.063ms
#  70.000%      700.415ms
#  80.000%      800.255ms
#  90.000%      900.095ms
# 100.000%     1000.447ms

puts hdr.latency_stats
#  Latency Stats
#  50.000%      500.223ms
#  75.000%      750.079ms
#  90.000%      900.095ms
#  99.000%      990.207ms
#  99.900%      999.423ms
#  99.990%      999.935ms
#  99.999%     1000.447ms
# 100.000%     1000.447ms
```

## API

#### `hdr = HDRHistogram.new(lowest_value, highest_value, significant_figures, multiplier: 1, unit: nil)`
Create new HDRHistogram object.
- `lowest_value`: The smallest possible value to be put into the histogram.  
- `highest_value`: The largest possible value to be put into the histogram.  
- `significant_figures`: The level of precision for this histogram, i.e. the number of figures in a decimal number that will be maintained.  E.g. a value of 3 will mean the results from the histogram will be accurate up to the first three digits. Must be a value between 1 and 5 (inclusive).
- `:multiplier`: A multiplier to adjust all incoming values. If present, the raw value recorded in the histogram for `record(val)` will be `val * 1/multiplier`. Similarly, `percentile(pctl) => val * multiplier`. If `multiplier` < 1, `lowest_value` can be < 1 so that `lowest_value` * 1/`multiplier` == 1.
- `:unit`: A unit for labeling histogram values. Useful for outputting things.
  
  

#### `hdr.record(value)`
Records a `value` in the histogram, will round this `value` of to a precision at or better than the `significant_figures` specified at construction time.  
Returns `false` if the value was not recorded, `true` otherwise.

#### `hdr.record_corrected(value, expected_interval)`
Record a `value` in the histogram and backfill based on an expected interval.  

This is specifically used for recording latency.  If the `value` is larger than the `expected_interval` then the latency recording system has experienced [co-ordinated omission](https://github.com/giltene/wrk2#acknowledgements). This method fills in the values that would have occured had the client providing the load not been blocked.  
Returns `false` if the value was not recorded, `true` otherwise.

#### `hdr.percentile(pct)`
Get the value at a specific percentile.

#### `hdr.count`
Get the total number of recorded values in the histogram.

#### `hdr.min`
Get minimum value from the histogram. Will return 0 if the histogram is empty.

#### `hdr.max`
Get maximum value from the histogram. Will return 0 if the histogram is empty.

#### `hdr.stddev`
Get the standard deviation for the values in the histogram.

#### `hdr.mean`
Get the mean (average) for the values in the histogram.

#### `hdr.reset`
Reset a histogram to zero - empty out a histogram and re-initialise it. If you want to re-use an existing histogram, but reset everything back to zero, this is the method to use.

#### `hdr.memsize`
Get the memory size (in bytes) of the histogram data.

#### `hdr.stats(percentiles=[10, 20, 30, 40, 50, 60, 70, 80, 90, 100])`
Get a formatted string with percentile stats of the histogram:
```
#  10.000%          100
#  20.000%          200
#  30.000%          300
#  40.000%          400 
#  50.000%          500
#  60.000%          600
#  70.000%          700
#  80.000%          800
#  90.000%          900
# 100.000%         1000
```
If the histogram was initialized with a `unit`, it will be shown after each percentile value.

#### `hdr.latency_stats`
Get a formatted string with percentile stats of the histogram useful for latency measurement:
```
#  Latency Stats
#  50.000%      500.223ms
#  75.000%      750.079ms
#  90.000%      900.095ms
#  99.000%      990.207ms
#  99.900%      999.423ms
#  99.990%      999.935ms
#  99.999%     1000.447ms
# 100.000%     1000.447ms
```
The above output assumes a :multiplier of 0.001 and a :unit of `:ms`
