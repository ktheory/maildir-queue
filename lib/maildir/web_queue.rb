require "maildir/queue"
require "sinatra/base"
require "json"

class Maildir::WebQueue < Sinatra::Base

  KEY_VALIDATOR = /^cur\/\d{10}\.\w+(\.\w+)+:2,(\w+)?$/

  class << self
    attr_accessor :queue
  end

  def queue
    self.class.queue
  end

  # Test that key is well-formed. If not, return 403 Forbidden error.
  def sanitize(key)
    # E.g. cur/1263444769.M975543P58179Q11.gnt.local:2,
    unless key.match(KEY_VALIDATOR)
      content_type "text/plain"
      halt 403, "Malformed key: #{key}"
    end
  end

  # Return a 204 No Content response
  def no_content
    halt 204, ""
  end

  # Check the server status
  get "/status" do
    content_type "application/json"
    {"new" => queue.list(:new).size,"cur" => queue.list(:cur).size}.to_json
  end

  # Create a new message. Requires params[:data]
  # Returns the message's key as json
  post "/message" do
    halt 400, "Must specify data parameter" unless params[:data]
    message = queue.push(params[:data])
    content_type "application/json"
    message.key.to_json
  end

  # Shift a new message off the queue
  get "/message" do
    message = queue.shift
    content_type "application/json"
    if message
      {"key" => message.key, "data" => message.data}.to_json
    else
      not_found "No pending messages".to_json
    end
  end

  # Delete a message from the queue
  delete "/message/*" do |key|
    sanitize(key)
    queue.delete(key)
    no_content
  end

  # # Update the timestamps on a message
  # post "/message/touch/*" do |key|
  #   sanitize(key)
  #   if queue.get(key).utime(Time.now, Time.now)
  #     no_content
  #   else
  #     not_found "Key #{key} does not exist"
  #   end
  # end
end

