require "test_helper"
require "pry"
class HDRHistogramTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::HDRHistogram::VERSION
  end

  def test_hdr_correct_record
    hdr = HDRHistogram.new(0.001,1000, 3, multiplier: 0.001)
    successful_responses = 1000
    expected_time = 0.01

    successful_responses.times { hdr.record(expected_time) }
    hdr.record_corrected((successful_responses * expected_time), expected_time)
    assert_equal hdr.percentile(10), 0.01
    assert_equal hdr.percentile(50), 0.01
    assert_equal hdr.percentile(75), 5.003
    assert_equal hdr.percentile(90), 8.003
    assert_equal hdr.percentile(99), 9.807
    assert_equal hdr.percentile(100), 10.007
  end
  
  def test_hdr_unserialize
    str = "1 10000000 0 3 10 1024 2047 2048 14 17 239 0 1.000000 15360 214 [~17 1 ~4 1 0 1 1 1 3 5 1 2 0 5 1 4 2 1 1 1 1 0 4 1 1 3 2 6 6 8 6 4 4 0 1 0 1 3 0 2 ~3 3 2 ~4 2 ~2 3 ~3 1 0 1 ~2 1 2 0 1 3 2 1 ~2 4 1 3 5 2 0 1 ~4 1 3 2 2 0 1 1 1 1 1 2 1 1 ~2 1 1 2 2 2 0 1 1 1 2 3 3 2 ~2 4 0 1 2 2 1 1 1 1 0 3 0 2 3 2 1 2 0 2 2 1 1 1 0 1 1 0 2 2 2 2 ~2 2 0 1 ~4 1 ~2 1 ~3 1 ~9 1 0 1 ~31 1 ~4 1 ~12 1 ~15120 ]"
    assert_raises(HDRHistogram::UnserializeError) do
      HDRHistogram.unserialize("banana")
    end
    
    hdr = HDRHistogram.unserialize(str, unit: "ms", multiplier: 0.001)
    
    assert_equal(hdr.stats, " 10.000%        0.032ms\n 20.000%        0.045ms\n 30.000%        0.049ms\n 40.000%        0.062ms\n 50.000%        0.089ms\n 60.000%        0.102ms\n 70.000%        0.123ms\n 80.000%        0.136ms\n 90.000%        0.152ms\n100.000%        0.239ms\n")
    
    assert_equal hdr.count, 214
    assert_in_epsilon hdr.stddev, 0.0476033319420351
  end

  def test_hdr

  end
end
