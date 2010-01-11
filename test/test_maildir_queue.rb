require 'helper'
class TestMaildirQueue < Test::Unit::TestCase

  context "A maildir queue" do

    setup { FakeFS::FileSystem.clear }

    should "shift messages" do
      temp_queue.add("1")
      temp_queue.add("2")
      message = temp_queue.shift
      assert_equal "1", message.data
    end

    should "put shifted messages in cur" do
      temp_queue.add("")
      message = temp_queue.shift
      assert_equal :cur, message.dir
    end

    should "list stalled messages" do
      temp_queue.add("")
      message = temp_queue.shift
      mtime = Time.now - 100
      message.utime(mtime, mtime)
      assert temp_queue.stalled_messages(Time.now - 50).include?(message)
    end

    should "requeue stalled messages" do
      data = "my data"
      temp_queue.add(data)
      stalled_message = temp_queue.shift
      mtime = Time.now - 100
      stalled_message.utime(mtime, mtime)
      temp_queue.requeue_stalled_messages(Time.now - 50)
      assert_equal data, temp_queue.list(:new).first.data
    end

    should "return the number of requeued stalled messages" do
      temp_queue.add("")
      stalled_message = temp_queue.shift
      mtime = Time.now - 100
      stalled_message.utime(mtime, mtime)
      assert_equal 1, temp_queue.requeue_stalled_messages(Time.now - 50)
    end
  end
end
