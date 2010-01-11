require 'maildir'
class Maildir::Queue < Maildir
  # How many times to retry getting a key
  LISTING_RETRIES = 3

  # Adds a new message to the queue. Returns a Maildir::Message object
  def push(data)
    add(data)
  end

  # Finds a new message and marks it as being processed (i.e. moves message
  # from new to cur). Returns message if successful; nil if there are no
  # pending messages.
  def shift
    retries = 0
    begin
      # Get a pending message
      message = list(:new, :limit => 1).first
      return nil if message.nil?

      # Move the message from new to cur
      if message.process
        return message
      else
        raise Errno::ENOENT
      end
    rescue Errno::ENOENT
      # Either message.process failed. Retry.
      if retry_count < LISTING_RETRIES
        retry_count += 1
        retry
      else
        # After several failures, act as if there are no pending messages
        return nil
      end
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
end