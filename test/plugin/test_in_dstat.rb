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
    Fluent::Test::Driver::Input.new(Fluent::Plugin::DstatInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 1, d.instance.delay
  end

  data do
    hash = {}
    OPTIONS.each do |op|
      hash[op] = op
    end
    hash
  end
  def test_emit(data)
    op = data
    conf = "tag dstat\n option --#{op}\n delay 1"
    emit_with_conf(conf)
  end

  def emit_with_conf(conf)
    d = create_driver(conf)

    d.run(expect_emits: 1)

    length = `dstat #{d.instance.option} #{d.instance.delay} 1`.split("\n")[0].split("\s").length
    puts `dstat #{d.instance.option} #{d.instance.delay} 3`

    events = d.events
    assert_equal true, events.length > 0
    assert_equal length, events[0][2]['dstat'].length

    puts "--- #{d.instance.option} ---"
    puts events[0][2]
    puts "--- end ---"
  end

end
