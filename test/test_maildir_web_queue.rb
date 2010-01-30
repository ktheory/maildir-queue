require 'helper'
class TestMaildirWebQueue < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Maildir::WebQueue.path = temp_queue.path
    Maildir::WebQueue
  end

  context "The WebQueue" do

    setup do
      FakeFS::FileSystem.clear
      @data = "my message"
    end

    should "have a status" do
      get "/status"
      assert last_response.ok?
    end

    should "accept posted messages" do
      post "/message", :data => @data
      assert last_response.ok?
    end

    should "add posted messages to the queue" do
      post "/message", :data => @data
      assert_equal 1, temp_queue.list(:new).size
    end

    should "save messages with the right data" do
      post "/message", :data => @data
      assert_equal @data, temp_queue.list(:new).first.data
    end

    should "return 404 when there are no new messages" do
      get "/message"
      assert_equal 404, last_response.status
    end

    should "return successfully when a new message exists" do
      post "/message", :data => @data
      get "/message"
      assert last_response.ok?
    end

    should "return a well-formed key when new a message exists" do
      post "/message", :data => @data
      get "/message"
      assert_match Maildir::WebQueue::KEY_VALIDATORS[0], JSON.parse(last_response.body)["key"]
    end

    should "return message data when a new message exits" do
      post "/message", :data => @data
      get "/message"
      assert_equal @data, JSON.parse(last_response.body)["data"]
    end

    should "return 404 when touching a missing message" do
      key = "cur/1234567890.M975543P58179Q11.host:2,"
      post "/touch/#{key}"
      assert_equal 404, last_response.status
    end

    should "touch a message" do
      message = temp_queue.add(@data)
      message.process

      post "/touch/#{message.key}"
      assert_equal 204, last_response.status
    end

    should "update a message's mtime when touched" do
      message = temp_queue.add(@data)
      message.process

      # Set mtime to 30 minutes ago
      message.utime(Time.now, Time.now - 30*60)

      post "/touch/#{message.key}"
      assert_in_delta Time.now, message.mtime, 1
    end
  end

  # Test Maildir::WebQueue::KEY_VALIDATORS
  bad_keys = [
    "/etc/passwd", "cur/../../etc/password", "..",
    "cur/123456789.M975543P58179Q11.host:2,",
    "cur/1234567890.M975543P58179Q11:2,",
    "cur/1234567890.M975543P58179Q11.host",
    "new/1234567890.M975543P58179Q11.host:2,",
    "tmp/1234567890.M975543P58179Q11.host:2,FRS"
  ]
  bad_keys.each_with_index do |key, i|
    define_method "test_bad_key_#{i}" do
      delete "/message/#{key}"
      assert_equal 403, last_response.status, "Key: #{key}"
    end
  end

  good_keys = [
    "cur/1234567890.M975543P58179Q11.host:2,",
    "cur/1234567890.abc123.really.long.domain.co.uk:2,",
    "cur/1234567890.M975543P58179Q11.host:2,FRS",
    "new/1234567890.M975543P58179Q11.host"
  ]
  good_keys.each_with_index do |key, i|
    define_method "test_good_key_#{i}" do
      delete "/message/#{key}"
      assert_not_equal 403, last_response.status, "Key: #{key}"
    end
  end
end
