#Ruby HdrHistogram Library

## Overview
HdrHistogram is an algorithm designed for recording histograms of value measurements with configurable precision.  Value precision is expressed as the number of significant digits, providing control over value quantization and resolution whilst maintaining a fixed cost in both space and time.
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

- ```ruby
  hdr = HDRHistogram.new(lowest_value, highest_value, significant_figures, multiplier: 1, unit: nil)
  ```
  `lowest_value`: The smallest possible value to be put into the histogram.  
  `highest_value`: The largest possible value to be put into the histogram.  
  `significant_figures`: The level of precision for this histogram, i.e. the number of figures in a decimal number that will be maintained.  E.g. a value of 3 will mean the results from the histogram will be accurate up to the first three digits. Must be a value between 1 and 5 (inclusive). 
  `:multiplier`: A multiplier to adjust all incoming values. If present, the raw value recorded in the histogram for `record(val)` will be `val * 1/multiplier`. Similarly, `percentile(pctl) => val * multiplier`. If `multiplier` < 1, `lowest_value` can be < 1 so that `lowest_value` * 1/`multiplier` == 1. 
  `:unit`: A unit for labeling histogram values. Useful for outputting things.  
  
- ```ruby
  hdr.record(value)
  ```
  Add value to histogram.

- ```ruby
  hdr.percentile(pct)
  ```
  Get histogram value at given percentile
  
- ```ruby
  hdr.record_corrected(value)
  ```
  Add value to histogram.
  
  
  
  
