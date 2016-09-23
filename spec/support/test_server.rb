require 'riak_test_server'

TEST_SERVER_HTTP_PORT = 10400
TEST_SERVER_PB_PORT = 10500

RSpec.configure do |config|
  config.before(:suite) do
    RiakTestServer.setup(
      http_port: TEST_SERVER_HTTP_PORT,
      pb_port: TEST_SERVER_PB_PORT,
      container_name: "ripple_tests"
    )
  end

  config.before(:each, integration: true) do
    RiakTestServer.clear
    Ripple.config = {
      nodes: [
        {
          host: "docker",
          http_port: TEST_SERVER_HTTP_PORT,
          pb_port: TEST_SERVER_PB_PORT
        }
      ]
    }
  end
end
