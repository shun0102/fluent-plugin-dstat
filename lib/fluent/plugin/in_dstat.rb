require 'fluent/plugin/input'

module Fluent::Plugin
  class DstatInput < Input

    Fluent::Plugin.register_input('dstat', self)

    helpers :timer, :event_loop

    def initialize
      super

      require 'csv'
      @line_number = 0
      @first_keys = []
      @second_keys = []
      @data_array = []
      @last_time = Time.now
    end

    # For fluentd v0.12.16 or earlier
    class << self
      unless method_defined?(:desc)
        def desc(description)
        end
      end
    end

    unless method_defined?(:log)
      define_method("log") { $log }
    end

    desc "the tag of event"
    config_param :tag, :string
    desc "dstat command path"
    config_param :dstat_path, :string, :default => "dstat"
    desc "dstat command line option"
    config_param :option, :string, :default => "-fcdnm"
    desc "Run dstat command every `delay` seconds"
    config_param :delay, :integer, :default => 1
    desc "Write dstat result to this file"
    config_param :tmp_file, :string, :default => "/tmp/fluent-plugin-dstat.fifo"
    desc "hostname command path"
    config_param :hostname_command, :string, :default => "hostname"

    def configure(conf)
      super

      @command = "#{@dstat_path} #{@option} --nocolor --output #{@tmp_file} #{@delay} > /dev/null 2>&1"
      @hostname = `#{@hostname_command}`.chomp!

      begin
        `#{@dstat_path} --version`
      rescue Errno::ENOENT
        raise ConfigError, "'#{@dstat_path}' command not found. Install dstat before run fluentd"
      end
    end

    def check_dstat
      now = Time.now
      if now - @last_time > @delay * 3
        log.info "Process dstat(#{@pid}) is stopped. Last updated: #{@last_time}"
        restart
      end
    end

    def start
      super
      system("mkfifo #{@tmp_file}")
      @io = IO.popen(@command, "r")
      @pid = @io.pid

      @dw = DstatCSVWatcher.new(@tmp_file, &method(:receive_lines))
      event_loop_attach(@dw)
      @tw = timer_execute(:in_dstat_timer, 1, &method(:check_dstat))
    end

    def shutdown
      Process.kill(:TERM, @pid)
      @dw.detach
      @tw.detach
      File.delete(@tmp_file)
      super
    end

    def restart
      Process.detach(@pid)
      begin
        Process.kill(:TERM, @pid)
      rescue Errno::ESRCH => e
        log.error "unexpected death of a child process", :error=>e.to_s
        log.error_backtrace
      end
      @dw.detach
      @tw.detach
      @line_number = 0

      @io = IO.popen(@command, "r")
      @pid = @io.pid
      @dw = DstatCSVWatcher.new(@tmp_file, &method(:receive_lines))
      event_loop_attach(@dw)
      @tw = timer_execute(:in_dstat_timer, 1, &method(:check_dstat))
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
            else
              @first_keys[index] = @first_keys[index].gsub(/\s/, '_')
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
          router.emit(@tag, Fluent::Engine.now, record)
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
        @io = File.open(path, File::NONBLOCK | File::TRUNC)
        @receive_lines = receive_lines
        @partial = ""
      end

      def on_change(prev, cur)
        buffer = @io.read_nonblock(65536)
        lines = buffer.split("\n").map(&:chomp)
        return if lines.empty?
        lines[0] = @partial + lines.first unless @partial.empty?
        @partial = buffer.end_with?("\n") ? "" : lines.pop
        @receive_lines.call(lines)
      rescue IO::WaitReadable
        # will be readable on next event
      end
    end

    class TimerWatcher < Cool.io::TimerWatcher
      def initialize(interval, repeat, &check_dstat)
        @check_dstat = check_dstat
        super(interval, repeat)
      end

      def on_timer
        @check_dstat.call
      rescue
        log.error $!.to_s
        log.error_backtrace
      end
    end
  end
end
