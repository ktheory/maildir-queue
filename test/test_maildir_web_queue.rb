require 'helper'
class TestMaildirWebQueue < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Maildir::WebQueue.queue = temp_queue
    Maildir::WebQueue
  end

  context "The webcontroller" do

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

    should "return 404 when no pending messages" do
      get "/message"
      assert_equal 404, last_response.status
    end

    should "return successfully when messages are pending" do
      post "/message", :data => @data
      get "/message"
      assert last_response.ok?
    end

    should "return a well-formed key when messages are pending" do
      post "/message", :data => @data
      get "/message"
      assert_match Maildir::WebQueue::KEY_VALIDATOR, JSON.parse(last_response.body)["key"]
    end

    should "return message data when messages are pending" do
      post "/message", :data => @data
      get "/message"
      assert_equal @data, JSON.parse(last_response.body)["data"]
    end

  end

  # Test the Maildir::WebQueue::KEY_VALIDATOR
  bad_keys = [ "/etc/passwd", "cur/../../etc/password",
    "cur/123456789.M975543P58179Q11.host:2,",
    "cur/1234567890.M975543P58179Q11:2,",
    "cur/1234567890.M975543P58179Q11.host"
  ]
  bad_keys.each_with_index do |key, i|
    define_method "test_bad_key_#{i}" do
      delete "/message/#{key}"
      assert_equal 403, last_response.status, "Key: #{key}"
    end
  end

  good_keys = [ "cur/1234567890.M975543P58179Q11.host:2,",
    "cur/1234567890.abc123.really.long.domain.co.uk:2,",
    "cur/1234567890.M975543P58179Q11.host:2,FRS"
  ]
  good_keys.each_with_index do |key, i|
    define_method "test_good_key_#{i}" do
      delete "/message/#{key}"
      assert last_response.successful?
    end
  end
end
