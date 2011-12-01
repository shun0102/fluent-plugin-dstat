require 'helper'

class DstatInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    tag dstat
    option -fcdnm 1
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::DstatInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal "-fcdnm 1", d.instance.option
  end

  def test_emit
    d = create_driver

    d.run do
      sleep 2
    end

    emits = d.emits
    assert_equal true, emits.length > 0
  end
end
