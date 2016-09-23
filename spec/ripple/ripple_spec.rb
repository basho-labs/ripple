require 'spec_helper'

describe Ripple do
  before do
    Ripple.config = {}
  end

  it "should have a client" do
    Ripple.client.should be_kind_of(Riak::Client)
  end

  it "should have a unique client per thread" do
    client = Ripple.client
    th = Thread.new { Ripple.client.should_not == client }
    th.join
  end

  it "should be configurable" do
    Ripple.should respond_to(:config)
  end

  it "should allow setting the client manually" do
    Ripple.should respond_to(:client=)
    client = Riak::Client.new(:http_port => 9000)
    Ripple.client = client
    Ripple.client.should == client
  end

  it "should reset the client when the configuration changes" do
    c = Ripple.client
    Ripple.config = {:http_port => 9000}
    Ripple.client.should_not == c
    Ripple.client.node.http_port.should == 9000
  end

  describe "date format" do
    before { @date_format = Ripple.date_format }
    after  { Ripple.date_format = @date_format }

    it "should default to :iso8601" do
      Ripple.date_format.should == :iso8601
    end

    it "should allow setting via the config" do
      Ripple.config = {"date_format" => "rfc822"}
      Ripple.date_format.should == :rfc822
    end

    it "should allow setting manually" do
      Ripple.date_format = "rfc822"
      Ripple.date_format.should == :rfc822
    end
  end
end
