module Fluent

class DstatInput < Input

  def split_second_key(str)
    result = []
    while (str)
      index = /[^ ] / =~ str
      if index
        result << str[0..index]
      else
        result << str unless str == " "
	return result
      end
      str = str[(index + 1)..-1]
    end

    return result
  end

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
        @first_keys = line.split(" ")
      when 1
        index = 0
        @first_keys.each do |i|
          @second_keys << line[index..(index + i.length - 1)]
          index += i.length + 1
        end
      else
        hash = Hash.new()
        values = []
        index = 0
        @first_keys.each do |i|
          values << line[index..(index + i.length - 1)]
          index += i.length + 1
        end

        @first_keys.each_with_index do |i, index|
          value_hash = Hash.new()
          first = i.gsub(/^-+|-+$/, "")
          length = i.length

          if first == "most-expensive"
            s_key = @second_keys[index].gsub(/^\s+|\s+$/, "")
            value_hash[s_key] = values[index]
          else
            keys = split_second_key(@second_keys[index])
            second_index = 0

            keys.each do |i|
              next_index = second_index + i.length - 1
              value = values[index][second_index..next_index]
              second_index += i.length + 1
              value = value.gsub(/^\s+|\s+$/, "") if value
              value_hash[i.gsub(/^\s+|\s+$/, "")] = value
            end
          end

          if hash[first].nil?
            hash[first] = value_hash
          else
            hash[first] = hash[first].merge(value_hash)
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
