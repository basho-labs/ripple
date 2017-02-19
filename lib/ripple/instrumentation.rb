#This file is pretty much just for POC
#TODO: backend instrumentation as needed by configuration (otherwise all three
#backends are loaded
#TODO: activate the log subscriber as configured (by default: not production)

require 'ripple/instrumentation/backend/beefcake'
require 'ripple/instrumentation/backend/net_http'
require 'ripple/instrumentation/backend/excon'
require 'ripple/instrumentation/log_subscriber'
