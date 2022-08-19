require "minitest/autorun"
require_relative '../check_996'

class TestParams < Minitest::Test

  def test_time_pass
    start_t = Time.now
    end_t = start_t + 10

    @gc = GitCounter.new({
      start_time: start_t,
      end_time: end_t
    })
    assert_equal start_t, @gc.start_time
    assert_equal end_t, @gc.end_time
  end
end