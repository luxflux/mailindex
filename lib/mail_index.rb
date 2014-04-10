require 'logger'

module MailIndex
  def self.logger
    @logger ||= Logger.new(STDOUT).tap { |logger| logger.level = Logger::WARN }
  end
end
