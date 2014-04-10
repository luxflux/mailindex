# encoding: utf-8

require 'mail'

require 'mail_index'

module MailIndex
  module Input

    class Mbox

      def initialize(es_connection, mbox_file, index_prefix)
        @es_connection = es_connection
        @mbox_file = mbox_file
        @index_prefix = index_prefix
      end

      def run
        @es_connection.indices.delete index: index rescue nil
        File.open @mbox_file, 'rb' do |file|
          buf = nil

          file.each_line do |line|
            # When we encounter the beginning of the next email,
            # yield the one we've been parsing and start over.
            if line =~ /\AFrom /
              index_mail(Mail.new(buf)) if buf
              buf = ''.force_encoding('binary')
            else
              buf << line
            end
          end

          # When we've read the whole file, yield the final email we parsed.
          index_mail(Mail.new(buf)) if buf
        end
      end

      def index_mail(mail)
        begin
          @es_connection.index index: index, type: :mail, id: id(mail), body: index_content(mail)
          MailIndex.logger.info "Indexed #{mail.subject}"
        rescue => error
          MailIndex.logger.error "Could not index mail with subject '#{mail.subject}': #{error.message}"
        end
      end

      def index
        "mailindex_#{@index_prefix}_#{Time.now.strftime('%F')}"
      end

      def id(mail)
        mail.message_id
      end

      def index_content(mail)
        {
          to: mail.to_addrs,
          cc: mail.cc_addrs,
          bcc: mail.bcc_addrs,
          subject: mail.subject,
          from: mail.from,
          body: body(mail),
        }
      end

      def body(mail)
        if mail.multipart?
          if mail.parts[0].multipart?
            mail.parts[0].parts[0].decoded.encode('UTF-8')
          else
            mail.parts[0].decoded.encode('UTF-8')
          end
        else
          mail.body.decoded.force_encoding(charset(mail)).encode('UTF-8')
        end
      end

      def headers(mail)
        mail.header.fields.map { |field| {field.name => field.value} }
      end

      def charset(mail)
        (mail.charset || 'US-ASCII') # http://www.ietf.org/rfc/rfc2045.txt, 5.2. Content-Type Defaults
      end

    end

  end
end
