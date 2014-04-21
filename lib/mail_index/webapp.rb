require 'elasticsearch'
require 'mail'
require 'erb'

module MailIndex
  class Webapp

    attr_reader :request, :template

    def initialize(request, template)
      @request = request
      @template = template

      @elasticsearch = Elasticsearch::Client.new log: false
    end

    def html_result
      template_engine.result(binding)
    end

    def search_results
      return nil unless @request.params['query']
      return @search_results if @search_results
      @search_results = @elasticsearch.search(index: index, type: :mail, size: 25, body: {query: query, highlight: highlight})['hits']['hits']
    end

    def query
      {
        query_string: {
          fields: %w[to cc bcc from subject^5 body],
          query: @request.params['query'],
          use_dis_max: true,
        },
      }
    end

    def highlight
      {
        pre_tags: ['<span class=highlight>'],
        post_tags: ['</span>'],
        fields: {
          _all: {number_of_fragments: 0},
          to: {},
          cc: {},
          bcc: {},
          from: {},
          subject: {},
          body: {number_of_fragments: 3},
        }
      }
    end

    def index
      "mailindex_#{remote_user}_*"
    end

    def remote_user
      @request.env['HTTP_REMOTE_USER'] || @request.env['HTTP_X_FORWARDED_USER']
    end

    private
    def template_engine
      @template_engine ||= ERB.new template
    end

  end

  class RackMiddleware

    def initialize(app_root)
      @app_root = app_root
    end

    def call(env)
      app = Webapp.new(Rack::Request.new(env), template)
      [200, {"Content-Type" => "text/html"}, [app.html_result]]
    end

    private
    def template
      @template ||= File.read(File.join(@app_root, 'views', 'application.html.erb'))
    end

  end
end
