require 'maildir'
class Maildir::Queue < Maildir

  # Adds a new message to the queue. Returns a Maildir::Message object
  def push(data)
    add(data)
  end

  # Finds a new message and marks it as being processed (i.e. moves message
  # from new to cur). Returns message if successful; nil if there are no
  # new messages.
  def shift
    loop do
      message = do_shift
      return message unless false == message
    end
  end

  # Returns messages in cur that haven't been modified since +time+
  def stalled_messages(time)
    list(:cur).select do |message|
      (mtime = message.mtime) && mtime < time
    end
  end

  # Returns a count of requeued messages
  def requeue_stalled_messages(time)
    stalled_messages(time).inject(0) do |count, message|
      begin
        push(message.data)
        message.destroy
        count + 1
      rescue Errno::ENOENT
        # Could not read message.data
        count
      end
    end
  end

  protected
  # Called by shift. Returns the first message in the queue; nil if no
  # messages are in the queue; or false if unable to process the message.
  def do_shift
    message = list(:new, :limit => 1).first
    return nil if message.nil?

    # Try to move the message from new to cur
    message.process ? message : false
  end
end