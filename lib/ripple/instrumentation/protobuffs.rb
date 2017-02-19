module Ripple
  module Instrumentation
    module Protobuffs
      extend ActiveSupport::Concern

      included do
        alias_method_chain :write_protobuff, :notification
        alias_method_chain :decode_response, :notification
      end

      def write_protobuffs_with_notification(*args, &block)
        payload = Hash[[:code, :message].zip(args)]
        ActiveSupport::Notifications.instrument('pbc_write.riak') do
          write_protobuffs_without_notifications(*args, &block)
        end
      end

      def decode_response_with_notification(*args, &block)
        ActiveSupport::Notifications.instrument('pbc_decode.riak') do
          decode_response_without_notifications(*args, &block)
        end
      end
    end
  end
end
