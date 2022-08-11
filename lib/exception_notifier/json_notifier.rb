require 'active_support/core_ext/time'
require 'action_dispatch'
require 'pp'

module ExceptionNotifier
  class JsonNotifier < ExceptionNotifier::BaseNotifier
    def initialize(opts)
      super
      @options  = opts
    end

    def call(exception, opts = {})
      title = exception.message || "None"
      @data = {title: title}
      ActiveSupport::Notifications.instrument("track.exception_track", title: title) do
        get_for_env(opts[:env])
        @data[:errors] = exception.inspect
        if  exception.backtrace.present?
          @data[:backtrace] = exception.backtrace
          backtrace = exception.backtrace.select{|x| !x.include?("lib/ruby/gems")}
          @data[:backtrace] = backtrace if backtrace.present?
        end

        Rails.logger.silence do
          filename = "#{@options[:app_name]}-#{Time.now}.json"
          File.write("#{Rails.root.to_s}/public/#{filename}", JSON.dump(@data))
        end
      end
    end

    # Log Request headers, session, environment from Rack env
    def get_for_env(env)
      return "" if env.blank?

      parameters = filter_parameters(env)
      request = ActionDispatch::Request.new(env)
      @data[:header]      = {}
      @data[:session]     = {}
      @data[:environment] = {}

      @data[:header]["URL"]                   = request.url
      @data[:header]["HTTP Method"]           = request.request_method
      @data[:header]["Parameters"]            = request.filtered_parameters.inspect
      @data[:header]["Controllers"]           = "#{parameters["controller"]}##{parameters["action"]}"
      @data[:header]["RequestId"]             = env["action_dispatch.request_id"]
      @data[:header]["User-Agent"]            = env["HTTP_USER_AGENT"]
      @data[:header]["Remote IP"]             = request.remote_ip
      @data[:header]["HTTP_ACCEPT_LANGUAGE"]  = env["HTTP_ACCEPT_LANGUAGE"]
      @data[:header]["Server"]                = Socket.gethostname
      @data[:header]["Process"]               = $PROCESS_ID

      session_id = request.ssl? ? "[FILTERED]" : (request.session['session_id'] || (request.env["rack.session.options"] and request.env["rack.session.options"][:id]).inspect)
      @data[:session]["session id"] = session_id
      @data[:session]["data"]       = PP.pp(request.session.to_hash, "")

      filtered_env = request.filtered_env
      filtered_env.keys.map(&:to_s).sort.each do |key|
        @data[:environment][key] = inspect_object(filtered_env[key])
      end
    end

    def inspect_object(object)
      case object
      when Hash, Array
        object.inspect
      else
        object.to_s
      end
    end

    def truncate(string, max)
      string.length > max ? "#{string[0...max]}..." : string
    end

    def filter_parameters(env)
      parameters = env["action_dispatch.request.parameters"] || {}
      parameter_filter = ActiveSupport::ParameterFilter.new(env["action_dispatch.parameter_filter"] || [])
      parameter_filter.filter(parameters)
        #
      rescue => e
        Rails.logger.error "filter_parameters error: #{e.inspect}"
        parameters
      #
    end

    def pretty_hash(params, indent = 0)
      json = JSON.pretty_generate(params)
      json.indent(indent)
    end

  end
end
