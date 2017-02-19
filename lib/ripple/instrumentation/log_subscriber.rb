module Ripple
  module Instrumentation
    class LogSubscriber < ActiveSupport::LogSubscriber
      def self.runtime=(value)
        Thread.current["riak_client_query_runtime"] = value
      end

      def self.runtime
        Thread.current["riak_client_query_runtime"] ||= 0
      end

      def self.reset_runtime
        rt, self.runtime = runtime, 0
        rt
      end

      def initialize
        super
        @even_line = false
      end

      def logger
        ActiveRecord::Base.logger
      end

      def colored(line)
        if @even_line = !@even_line
          color(line, CYAN, true)
        else
          color(line, MAGENTA, true)
        end
      end

      def http_perform(event)
        self.class.runtime += event.duration
        return unless logger.debug?

        payload = event.payload
        debug(colored('HTTP: %s (%.2fms) %s %s:' % [payload[:method].upcase, event.duration, payload[:uri], payload[:headers].inspect]))
        debug(payload[:data]) unless payload[:data].nil?
      end

      def pbc_write(event)
        self.class.runtime += event.duration
        return unless logger.debug?

        payload = event.payload
        line  = 'PBC: %s (%.2fms) %s' % [payload[:code], event.duration, payload[:message].inspect]
        debug(colored(line))
      end

      def pbc_decode(event)
        self.class.runtime += event.duration
        return unless logger.debug?

        payload = event.payload
        debug(colored('PBC DECODE (%.2fms)' % [event.duration]))
      end
    end
  end
end
ActiveRecord::LogSubscriber.attach_to :riak
