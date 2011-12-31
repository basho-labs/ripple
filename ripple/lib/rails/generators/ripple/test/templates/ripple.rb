require 'ripple/test_server'
Ripple::TestServer.setup

After do
  Ripple::TestServer.clear
end
