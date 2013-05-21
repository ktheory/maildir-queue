require "maildir/queue"
require "sinatra/base"
require "json"

class Maildir::WebQueue < Sinatra::Base

  KEY_VALIDATORS = [
    /^cur\/\d{10}\.[\w-]+(\.[\w-]+)+:2,(\w+)?$/, # cur keys, with info
    /^new\/\d{10}\.[\w-]+(\.[\w-]+)+$/ # new keys, no info
  ]

  def self.path=(path)
    @@queue = Maildir::Queue.new(path)
  end

  def queue
    @@queue
  end

  # Test that key is well-formed. If not, return 403 Forbidden error.
  def sanitize(key)
    # E.g. cur/1263444769.M975543P58179Q11.gnt.local:2,
    unless KEY_VALIDATORS.any?{|validator| key.match(validator) }
      content_type "text/plain"
      halt 403, "Malformed key: #{key}"
    end
  end

  # Return a 204 No Content response
  def no_content
    halt 204, ""
  end

  # Set the content type to JSON and returns the body as JSON
  def json(body)
    content_type "application/json"
    body.to_json
  end

  # Check the server status
  get "/status" do
    body = {"new" => queue.list(:new).size,"cur" => queue.list(:cur).size}
    json(body)
  end

  # Create a new message. Requires params[:data]
  # Returns the message's key as json
  post "/message" do
    halt 400, "Must specify data parameter" unless params[:data]
    message = queue.push(params[:data])
    json(message.key)
  end

  # Shift a new message off the queue
  get "/message" do
    message = queue.shift

    if message
      json({"key" => message.key, "data" => message.data})
    else
      not_found json("No new messages")
    end
  end

  # Delete a message from the queue
  delete %r{/message/*} do |key|
    sanitize(key)
    if queue.delete(key)
      no_content
    else
      not_found json("Key #{key} does not exist")
    end
  end

  # Update the timestamps on a message
  post %r{/touch/*} do |key|
    sanitize(key)
    if queue.get(key).utime(Time.now, Time.now)
      no_content
    else
      not_found json("Key #{key} does not exist")
    end
  end
end

