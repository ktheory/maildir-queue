# A rackup file suitable for thin, passenger, unicorn, etc.

require "maildir/web_queue"
Maildir::WebQueue.path = "/tmp/my_maildir"
run Maildir::WebQueue