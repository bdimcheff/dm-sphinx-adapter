require 'rubygems'

gem 'riddle', '~> 0.9'
require 'riddle'

module DataMapper
  class SphinxClient
    def initialize(uri_or_options)
      @config = SphinxConfig.new(uri_or_options)
    end

    # TODO: What about filters?
    def search(query, indexes = '*', options = {})
      indexes = indexes.join(' ') if indexes.kind_of?(Array)

      client = Riddle::Client.new(@config.address, @config.port)
      options.each{|k, v| client.method("#{k}=".to_sym).call(v) if client.respond_to?("#{k}=".to_sym)}
      client.query(query, indexes.to_s)
    end

    ##
    # Index one or more indexes.
    #
    # @param [Array, String] indexes Defaults to --all if indexes is nil or '*'.
    def index(indexes = nil, options = {})
      indexes = indexes.join(' ') if indexes.kind_of?(Array)

      command = @config.indexer_bin
      command << " --rotate" if running?
      command << ((indexes.nil? || indexes == '*') ? ' --all' : " #{indexes.to_s}")
      warn "Sphinx: Indexer #{$1}" if `#{command}` =~ /(?:error|fatal|warning):?\s*([^\n]+)/i
    end

    protected

      ##
      # Is the client running.
      #
      # Tests the address and port set in the configuration file.
      def running?
        !!TCPSocket.new(@config.address, @config.port) rescue nil
      end
  end # SphinxClient

  ##
  # Managed searchd if you don't already have god/monit doing the job for you.
  #
  # Requires you have daemon_controller installed.
  # @see http://github.com/FooBarWidget/daemon_controller/tree/master
  class SphinxManagedClient < SphinxClient
    def initialize(url_or_options)
      super

      # Fire up searchd.
      require 'daemon_controller'
      @client = DaemonController.new(
        :identifier    => 'Sphinx searchd',
        :start_command => @config.searchd_bin,
        :stop_command  => "#{@config.searchd_bin} --stop",
        :ping_command  => method(:running?),
        :pid_file      => @config.pid_file,
        :log_file      => @config.log
      )
    end

    def search(*args)
      @client.connect do
        super *args
      end
    end

    def stop
      @client.stop
    end
  end # SphinxManagedClient
end # DataMapper