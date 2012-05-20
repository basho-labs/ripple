module Ripple
  module Instrumentation
    module HTTP
      extend ActiveSupport::Concern

      included do
        alias_method_chain :perform, :notification
      end

      def perform_with_notification(*args, &block)
        payload = Hash[[:method, :uri, :headers, :expect, :data].zip(args)]
        ActiveSupport::Notifications.instrument('http_perform.riak', payload) do
          perform_without_notifications(*args, &block)
        end
      end
    end
  end
end

module Riak::Client
  class NetHTTPBackend
    include Ripple::Instrumentation::HTTP
  end
  class ExconBackend
    include Ripple::Instrumentation::HTTP
  end
end
