require 'ripple/instrumentation/protobuffs'
require 'riak/client/beefcake_protobuffs_backend'

class Riak::Client::BeefcakeProtobuffsBackend
  include Ripple::Instrumentation::Protobuffs
end
