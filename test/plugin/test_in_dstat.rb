require 'helper'

class DstatInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  OPTIONS = ["aio", "cpu", "cpu24", "disk", 
             "epoch", "fs", "int", "int24", "io", "ipc", "load", "lock",
             "mem", "net", "page", "page24", "proc", "raw", "socket",
             "swap", "swapold", "sys", "tcp", "udp", "unix", "vm",
             "disk-util", "freespace",
             "top-bio", "top-cpu","top-io",
             "top-mem", "top-oom", "top-io -fc"]

  CONFIG = %[
    tag dstat
    option --aio -cpu
    delay 1
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::DstatInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 1, d.instance.delay
  end

  def test_emit

    OPTIONS.each do |op|
      conf = "tag dstat\n option --#{op}\n delay 1"
      emit_with_conf(conf)
    end

  end

  def emit_with_conf(conf)
    d = create_driver(conf)

    d.run do
      sleep 2
    end

    length = `dstat #{d.instance.option} #{d.instance.delay} 1`.split("\n")[0].split("\s").length
    puts `dstat #{d.instance.option} #{d.instance.delay} 3`

    emits = d.emits
    assert_equal true, emits.length > 0
    assert_equal length, emits[0][2]['dstat'].length

    puts "--- #{d.instance.option} ---"
    puts emits[0][2]
    puts "--- end ---"
  end

end
