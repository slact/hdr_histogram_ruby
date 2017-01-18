require "test_helper"

class HDRHistogramTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::HDRHistogram::VERSION
  end

  def test_hrd_correct_record
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

  def test_hdr

  end
end
