require 'helper'
class TestMaildirQueue < Test::Unit::TestCase

  context "A maildir queue" do

    setup { FakeFS::FileSystem.clear }

    should "return nil if no messages to shift" do
      assert_equal nil, queue.shift
    end

    should "shift messages" do
      queue.add("1")
      queue.add("2")
      message = queue.shift
      assert_equal "1", message.data
    end

    should "put shifted messages in cur" do
      queue.add("")
      message = queue.shift
      assert_equal :cur, message.dir
    end

    should "list stalled messages" do
      queue.add("")
      message = queue.shift
      mtime = Time.now - 100
      message.utime(mtime, mtime)
      assert queue.stalled_messages(Time.now - 50).include?(message)
    end

    should "requeue stalled messages" do
      data = "my data"
      queue.add(data)
      stalled_message = queue.shift
      mtime = Time.now - 100
      stalled_message.utime(mtime, mtime)
      queue.requeue_stalled_messages(Time.now - 50)
      assert_equal data, queue.list(:new).first.data
    end

    should "return the number of requeued stalled messages" do
      queue.add("")
      stalled_message = queue.shift
      mtime = Time.now - 100
      stalled_message.utime(mtime, mtime)
      assert_equal 1, queue.requeue_stalled_messages(Time.now - 50)
    end
  end
end
