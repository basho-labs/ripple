require 'ripple/instrumentation/http'
require 'riak/client/excon_backend'

module Riak::Client
  class ExconBackend
    include Ripple::Instrumentation::HTTP
  end
end
