require 'ripple/instrumentation/http'
require 'riak/client/net_http_backend'

module Riak::Client
  class NetHTTPBackend
    include Ripple::Instrumentation::HTTP
  end
end
