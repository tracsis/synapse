require 'datadog/statsd'
require 'synapse/log'

module Synapse
  module StatsD
    def statsd
      @@STATSD ||= StatsD.statsd_for(self.class.name)
    end

    def statsd_increment(key, tags = [])
      if @@STATSD_FORMAT_DATADOG
        statsd.increment(key, tags: tags, sample_rate: sample_rate_for(key))
      else
        statsd.increment(key, tags: [], sample_rate: sample_rate_for(key))
      end
    end

    def statsd_time(key, tags = [])
      if @@STATSD_FORMAT_DATADOG
        statsd.time(key, tags: tags, sample_rate: sample_rate_for(key)) do
          yield
        end
      else
        statsd.time(key, tags: [], sample_rate: sample_rate_for(key)) do
          yield
        end
      end
    end

    class << self
      include Logging

      @@STATSD_HOST = "localhost"
      @@STATSD_PORT = 8125
      @@STATSD_SAMPLE_RATE = {}
      @@STATSD_FORMAT_DATADOG = true

      def statsd_for(classname)
        log.debug "synapse: creating statsd client for class '#{classname}' on host '#{@@STATSD_HOST}' port #{@@STATSD_PORT}"
        Datadog::Statsd.new(@@STATSD_HOST, @@STATSD_PORT)
      end

      def configure_statsd(opts)
        @@STATSD_HOST = opts['host'] || @@STATSD_HOST
        @@STATSD_PORT = (opts['port'] || @@STATSD_PORT).to_i
        @@STATSD_SAMPLE_RATE = opts['sample_rate'] || {}
        @@STATSD_FORMAT_DATADOG = ((opts['format'] || "datadog") == "datadog")
        if @@STATSD_FORMAT_DATADOG
          log.info "synapse: configuring statsd for datadogging on host '#{@@STATSD_HOST}' port #{@@STATSD_PORT}"
        else
          log.info "synapse: configuring statsd for normal behaviour on host '#{@@STATSD_HOST}' port #{@@STATSD_PORT}"
        end
      end
    end

    private

    def sample_rate_for(key)
      rate = @@STATSD_SAMPLE_RATE[key]
      rate.nil? ? 1 : rate
    end
  end
end
