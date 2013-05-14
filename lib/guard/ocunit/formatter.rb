require 'guard/ocunit'
require 'colored'

class Guard::OCUnit::Formatter < Array
  attr_reader :passed, :failed, :start_time

  def initialize(io, verbose)
    @io, @verbose     = io, verbose
    @failed, @passed  = 0, 0
    @start_time       = Time.now
  end

  def <<(line)
    super
    @io << case line
    when /passed/
      @passed += 1
      @verbose ? line.green : ''
    when /failed/
      @failed += 1
      line.red
    when /(error|otest)/
      line.split(':')[3..-1].join(' ').yellow
    else
      @verbose ? line : ''
    end
    self
  end

  def dump_summary(with_notification=true)
    end_time = Time.now
    duration = end_time - @start_time
    message = guard_message(@passed + @failed, @failed, 0, duration)
    image   = guard_image(@failed, 0)
    Guard::UI.info(message.gsub("\n", ' '), :reset => true)
    notify(message, image) if with_notification
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
end
