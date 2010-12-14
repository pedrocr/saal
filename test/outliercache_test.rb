require File.dirname(__FILE__)+'/test_helper.rb'

class TestOutlierCache < Test::Unit::TestCase
  def test_clean_setup
    cache = SAAL::OutlierCache.new
    assert !cache.live, "Live empty cache"
    20.times {cache.validate(10)}
    assert cache.live, "Not Live full cache"
  end

  def test_failed_dirty_setup
    cache = SAAL::OutlierCache.new
    assert !cache.live, "Live empty cache"
    (1..20).each {|i| cache.validate(i)}
    assert !cache.live, "Live cache with dirty results"
  end

  def test_working_dirty_setup
    cache = SAAL::OutlierCache.new
    assert !cache.live, "Live empty cache"
    [1,1,1,2,1,1,1,1,1,1,1,1,1].each {|i| cache.validate(i)}
    assert cache.live, "Not Live full cache"
  end

  def test_validate
    cache = SAAL::OutlierCache.new
    20.times {cache.validate(10)}
    assert cache.live, "Not Live full cache"
    assert cache.validate(10), "Non validated good value"
    assert !cache.validate(15), "Validated bad value"
  end

  def test_setup_recover_from_discontinuity
    cache = SAAL::OutlierCache.new
    20.times {cache.validate(10)}
    assert cache.live, "Not Live full cache"
    20.times {cache.validate(15)}
    assert cache.live, "Not Live full cache"
    assert cache.validate(15), "Non validated good value"
    assert !cache.validate(10), "Validated bad value"
  end
end
