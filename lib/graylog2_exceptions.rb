require 'rubygems'
require 'gelf'
require 'socket'

class Graylog2Exceptions
  def initialize(app, options)
    @gl2_hostname = options[:host] || "localhost"
    @gl2_port = options[:port] || 12201
    @local_app_name = options[:local_app_name] || Socket::gethostname

    @app = app
  end

  def call(env)
    # Make thread safe
    dup._call(env)
  end

  def _call(env)
    begin
      # Call the app we are monitoring
      @app.call(env)
    rescue StandardError, SyntaxError, LoadError => err
      # An exception has been raised. Send to Graylog2!
      send_to_graylog2(err)

      # Raise the exception again to pass back to app.
      raise
    end
  end

  def send_to_graylog2 err
    begin
      gelf = Gelf.new @gl2_hostname, @gl2_port
      gelf.short_message = err.message
      gelf.full_message = err.backtrace.join("\n")
      gelf.level = @level
      gelf.host = @local_app_name
      gelf.file = err.backtrace[0].split(":")[0]
      gelf.line = err.backtrace[0].split(":")[1]
      gelf.send
    rescue => i_err
      puts "Graylog2 Exception logger. Could not send message: " + i_err.message
    end
  end
end
