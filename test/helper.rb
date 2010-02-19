require 'test/unit'
require 'shoulda'
require 'rack/test'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'maildir/queue'
require 'maildir/web_queue'

# Require 'ktheory-fakefs' until issues 28, 29, and 30 are resolved in
# defunkt/fakefs. See http://github.com/defunkt/fakefs/issues
gem "ktheory-fakefs"
require 'fakefs'


# Create a reusable MaildirQueue that's cleaned up when the tests are done
def queue
  Maildir::Queue.new("/tmp/maildir_queue_test")
end
