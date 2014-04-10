app_root = File.expand_path('../', __FILE__)

$: << File.join(app_root, 'lib')

require 'mail_index/webapp'

run MailIndex::RackMiddleware.new(app_root)

