require 'guard/ocunit'
require 'colored'

class Guard::OCUnit::Formatter < Array
  attr_reader :passed, :failed, :start_time, :error_messages

  def initialize(io, verbose)
    @io, @verbose     = io, verbose
    @failed, @passed  = 0, 0
    @start_time       = Time.now
    @error_messages   = []
    @current_failure = ''
  end

  def <<(line)
    super
    @io << case line
    when /passed/
      @passed += 1
      (@verbose ? line : '.' ).green
    when /failed/
      format_current_messages
      @failed += 1
      (@verbose ? line : 'F' ).red
    when /(error|otest)/
      @current_failure << line
      @verbose ? line.yellow : ''
    when /(started|Executed|finished)/
      @verbose ? line : ''
    when /^#{Date.today}/
      line
    else
      @current_failure << line unless line.strip.empty?
      @verbose ? line : ''
    end
    self
  end

  def dump_summary(with_notification=true)
    dump_error_messages

    end_time = Time.now
    duration = end_time - @start_time
    message = guard_message(@passed + @failed, @failed, 0, duration)
    image   = guard_image(@failed, 0)
    Guard::UI.info(message.gsub("\n", ' '), :reset => true)
    notify(message, image) if with_notification
  end

  def dump_error_messages
    return if @error_messages.empty?

    puts "\n\nFailures:\n"
    puts @error_messages.join + "\n"
  end

  def guard_message(example_count, failure_count, pending_count, duration)
    message = "#{example_count} examples, #{failure_count} failures"
    if pending_count > 0
      message << " (#{pending_count} pending)"
    end
    message << "\nin #{duration.round(4)} seconds"
    message
  end

  # failed | pending | success
  def guard_image(failure_count, pending_count)
    if failure_count > 0
      :failed
    elsif pending_count > 0
      :pending
    else
      :success
    end
  end

  def priority(image)
    { :failed => 2,
      :pending => -1,
      :success => -2
    }[image]
  end

  def notify(message, image)
    Guard::Notifier.notify(message, :title => "OCUnit results", :image => image,
      :priority => priority(image))
  end

private

  def format_current_messages
    format_failure(@current_failure) unless @current_failure.empty?
    @current_failure = ''
  end

  def format_failure(messages)
    location          = 0
    header_added      = false
    formatted_message = ''

    while ( match = messages.match(/\n#{Dir.pwd}/, location) )
      match_location = match.begin(0)

      message = messages.slice(location, match_location - location)
      unless header_added
        formatted_message << failure_case(message)
        header_added = true
      end
      formatted_message << failure_reason(message)

      location = match_location + 1
    end
    message = messages.slice(location, messages.length - location)
    formatted_message << failure_case(message) unless header_added
    formatted_message << failure_reason(message)
    
    @error_messages << formatted_message
  end

  def failure_case(failure)
    components = failure.split(':')
    case_name = "\n#{@error_messages.size + 1}."
    case_name << components[3]
  end

  def failure_reason(failure)
    components = failure.split(':')
    failure_reason = "\n    "
    failure_reason << components[4..-1].join.rstrip.red 
    failure_reason << "\n    "
    failure_reason << "#{components[0].gsub(Dir.pwd, '.')}:#{components[1]}".green
    failure_reason << "\n"
  end
end
