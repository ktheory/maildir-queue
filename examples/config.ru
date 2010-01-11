require "maildir/web_queue"
maildir_path = "/tmp/my_maildir"
Maildir::WebQueue.queue = Maildir::Queue.new(maildir_path)
Maildir::WebQueue.run!