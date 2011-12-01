module Fluent


class DstatInput < Input
  Plugin.register_input('dstat', self)

  def initialize
    super
    @hostname = `hostname -s`.chomp!
    @line_number = 0
    @first_keys = []
  end

  config_param :tag, :string
  config_param :option, :string, :default => "-fcdnm 1"

  def configure(conf)
    super
    @command = "dstat #{@option}"
  end

  def start
    @io = IO.popen(@command, "r")
    @pid = @io.pid
    @thread = Thread.new(&method(:run))
  end

  def shutdown
    Process.kill(:TERM, @pid)
    if @thread.join(60)  # TODO wait time
      return
    end
    Process.kill(:KILL, @pid)
    @thread.join
  end

  def run
    @io.each_line(&method(:each_line))
  end

  private
  def each_line(line)
    begin
      line.chomp!
      line.gsub!(/\e\[7l/, "")

      case @line_number
      when 0
        @first_keys = line.split(" ").map {|i| i.gsub(/^-+|-+$/, "") }
      when 1
        @second_keys = Array.new( @first_keys.length, nil)
        line.split(/[:\|]/).each_with_index do |i, index|
          keys = i.split(" ")
          @second_keys[index] = keys
        end
      else
        hash = Hash.new()
        line.split(/[:\|]/).each_with_index do |i, index|
          keys = i.split(" ")
          value_hash = Hash.new()
          @second_keys[index].each_with_index do |j, second_index|
            value_hash[j] = keys[second_index]
          end
          hash[@first_keys[index]] = value_hash
        end
        record = {
          'hostname' => @hostname,
          'dstat' => hash
        }
        Engine.emit(@tag, Engine.now, record)
      end
      @line_number += 1

    rescue
      $log.error "exec failed to emit", :error=>$!, :line=>line
      $log.warn_backtrace $!.backtrace
    end
  end
end


end
