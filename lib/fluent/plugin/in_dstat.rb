module Fluent


class DstatInput < Input
  Plugin.register_input('dstat', self)

  def initialize
    super
    @hostname = `hostname -s`.chomp!
    @line_number = 0
    @first_keys = []
    @second_keys = []
  end

  config_param :tag, :string
  config_param :option, :string, :default => "-fcdnm"
  config_param :delay, :integer, :default => 1

  def configure(conf)
    super
    @command = "dstat #{@option} #{@delay}"
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
        @second_keys = line.split(/[:\|]/)
      else
        hash = Hash.new()
        values = line.split(/[:\|]/)

        @first_keys.each_with_index do |i, index|
          value_hash = Hash.new()
          if /^most/ =~ i
            s_key = @second_keys[index].gsub(/^\s+|\s+$/, "")
            value_hash[s_key] = values[index]
          else
            second_values = values[index].split(" ")
            @second_keys[index].split(" ").each_with_index do |j, second_index|
              value_hash[j] = second_values[second_index]
            end
          end
          if hash[@first_keys[index]].nil?
            hash[@first_keys[index]] = value_hash
          else
            hash[@first_keys[index]] = hash[@first_keys[index]].merge(value_hash)
          end
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
