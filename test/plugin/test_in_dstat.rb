require 'helper'

class DstatInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    tag dstat
    option -fcdnm
    delay 1
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::DstatInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal "-fcdnm", d.instance.option
    assert_equal 1, d.instance.delay
  end

  def test_emit
    d = create_driver

    d.run do
      sleep 2
    end

    length = `dstat #{d.instance.option} #{d.instance.delay} 1`.split("\n")[0].split("\s").length
    emits = d.emits
    assert_equal true, emits.length > 0
    puts emits[0][2]['dstat']
    assert_equal length, emits[0][2]['dstat'].length
  end

end
