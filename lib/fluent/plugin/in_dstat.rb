module Fluent

class DstatInput < Input

  Plugin.register_input('dstat', self)

  def initialize
    super
    require 'csv'
    @line_number = 0
    @first_keys = []
    @second_keys = []
    @data_array = []
    @max_lines = 100
    @last_time = Time.now
  end

  config_param :tag, :string
  config_param :option, :string, :default => "-fcdnm"
  config_param :delay, :integer, :default => 1
  config_param :tmp_file, :string, :default => "/tmp/dstat.csv"
  config_param :hostname_command, :string, :default => "hostname"

  def configure(conf)
    super
    @command = "dstat #{@option} --output #{@tmp_file} #{@delay}"
    @hostname = `#{@hostname_command}`.chomp!
  end

  def check_dstat
    restart if (Time.now - @last_time) > @delay*3
  end

  def start
    touch_or_truncate(@tmp_file)
    @io = IO.popen(@command, "r")
    @pid = @io.pid

    @loop = Coolio::Loop.new
    @dw = DstatCSVWatcher.new(@tmp_file, &method(:receive_lines))
    @dw.attach(@loop)
    @tw = TimerWatcher.new(1, true,  &method(:check_dstat))
    @tw.attach(@loop)
    @thread = Thread.new(&method(:run))
  end

  def shutdown
    Process.kill(:TERM, @pid)
    @dw.detach
    @tw.detach
    @loop.stop
    @thread.join
    File.delete(@tmp_file)
  end

  def run
    begin
      @loop.run
    rescue
      $log.error "unexpected error", :error=>$!.to_s
      $log.error_backtrace
    end
  end

  def restart
    Process.detach(@pid)
    Process.kill(:TERM, @pid)
    @dw.detach
    @tw.detach
    @line_number = 0
    touch_or_truncate(@tmp_file)

    @io = IO.popen(@command, "r")
    @pid = @io.pid
    @dw = DstatCSVWatcher.new(@tmp_file, &method(:receive_lines))
    @dw.attach(@loop)
    @tw = TimerWatcher.new(1, true,  &method(:check_dstat))
    @tw.attach(@loop)
  end

  def touch_or_truncate(file)
    if File.exist?(file)
      File.truncate(file, 0)
    else
      `touch #{file}`
    end
  end

  def receive_lines(lines)
    lines.each do |line|
      next if line == ""
      case @line_number
      when 0..1
      when 2
        line.delete!("\"")
        @first_keys = CSV.parse_line(line)
        pre_key = ""
        @first_keys.each_with_index do |key, index|
          if key.nil? || key == ""
            @first_keys[index] = pre_key
          end
          pre_key = @first_keys[index]
        end
      when 3
        line.delete!("\"")
        @second_keys = line.split(',')
        @first_keys.each_with_index do |key, index|
          @data_array[index] = {}
          @data_array[index][:first] = key
          @data_array[index][:second] = @second_keys[index]
        end
      else
        values = line.split(',')
        data = Hash.new { |hash,key| hash[key] = Hash.new {} }
        values.each_with_index do |v, index|
          data[@first_keys[index]][@second_keys[index]] = v
        end
        record = {
          'hostname' => @hostname,
          'dstat' => data
        }
        Engine.emit(@tag, Engine.now, record)
      end

      if (@line_number % @max_lines) == (@max_lines - 1)
        @dw.detach
        File.truncate(@tmp_file, 0)
        @dw = DstatCSVWatcher.new(@tmp_file, &method(:receive_lines))
        @dw.attach(@loop)
      end

      @line_number += 1
      @last_time = Time.now
    end

  end

  class DstatCSVWatcher < Cool.io::StatWatcher
    INTERVAL = 0.500
    attr_accessor :previous, :cur

    def initialize(path, &receive_lines)
      super path, INTERVAL
      @path = path
      @io = File.open(path)
      @pos = 0
      @receive_lines = receive_lines
    end

    def on_change(prev, cur)
      buffer = @io.read(cur.size - @pos)
      @pos = cur.size
      lines = []
      while line = buffer.slice!(/.*?\n/m)
        lines << line.chomp
      end
      @receive_lines.call(lines)
    end
  end
  class TimerWatcher < Coolio::TimerWatcher
    def initialize(interval, repeat, &check_dstat)
      @check_dstat = check_dstat
      super(interval, repeat)
    end

    def on_timer
      @check_dstat.call
    rescue
      $log.error $!.to_s
      $log.error_backtrace
    end
  end
end


end
