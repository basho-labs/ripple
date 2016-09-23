require 'riak'
require 'erb'
require 'yaml'
require 'active_model'
require 'ripple/core_ext'
require 'ripple/translation'
require 'ripple/document'
require 'ripple/embedded_document'

# Contains the classes and modules related to the ODM built on top of
# the basic Riak client.
module Ripple
  class << self
    # @return [Riak::Client] The client for the current thread.
    def client
      Thread.current[:ripple_client] ||= Riak::Client.new(client_config)
    end

    # Sets the client for the current thread.
    # @param [Riak::Client] value the client
    def client=(value)
      Thread.current[:ripple_client] = value
    end

    # Sets the global Ripple configuration.
    def config=(hash)
      self.client = nil
      @config = hash.symbolize_keys
    end

    # Reads the global Ripple configuration.
    def config
      @config
    end

    # The format in which date/time objects will be serialized to
    # strings in JSON.  Defaults to :iso8601, and can be set in
    # Ripple.config.
    # @return [Symbol] the date format
    def date_format
      (config[:date_format] ||= :iso8601).to_sym
    end

    # Sets the format for date/time objects that are serialized to
    # JSON.
    # @param [Symbol] format the date format
    def date_format=(format)
      config[:date_format] = format.to_sym
    end

    private

    def expect_config
      config or raise(MissingConfiguration.new("No configuration set"))
    end

    def client_config
      expect_config.slice(*Riak::Client::VALID_OPTIONS)
    end
  end

  # Exception raised when the path passed to
  # {Ripple::load_configuration} does not point to a existing file.
  class MissingConfiguration < StandardError
  end
end

require 'ripple/railtie' if defined? Rails::Railtie
