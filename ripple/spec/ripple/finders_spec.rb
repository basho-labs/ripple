require File.expand_path("../../spec_helper", __FILE__)

describe Ripple::Document::Finders do
  require 'support/models/box'
  require 'support/models/cardboard_box'
  
  before :each do
    @backend = mock("Backend")
    @client = Ripple.client
    @client.stub!(:backend).and_return(@backend)
    @bucket = Ripple.client.bucket("boxes")
    @plain = Riak::RObject.new(@bucket, "square"){|o| o.content_type = "application/json"; o.raw_data = '{"shape":"square"}'}
    @cb = Riak::RObject.new(@bucket, "rectangle"){|o| o.content_type = "application/json"; o.raw_data = '{"shape":"rectangle"}'}
    @not_found = Riak::RObject.new(@bucket, "missing") do |o|
      o.content_type = "application/json"
      o.raw_data = '{"not_found": {"bucket": "boxes", "key": "rectangle", "keydata": "undefined"}}'
    end
  end

  it "should return nil if no keys are passed to find" do
    Box.find().should be_nil
  end

  it "should return nil if no valid keys are passed to find" do
    Box.find(nil).should be_nil
    Box.find("").should be_nil
  end
  
  it "should raise Ripple::DocumentNotFound if an empty array is passed to find!" do
    lambda { Box.find!() }.should raise_error(Ripple::DocumentNotFound, "Couldn't find document without a key")
  end

  describe "finding single documents" do
    before do
      @bucket.stub!(:get).with("square", {}).and_return(@plain)
    end
    
    it "should find a single document by key and assign its attributes" do
      @bucket.should_receive(:get).with("square", {}).and_return(@plain)
      box = Box.find("square")
      box.should be_kind_of(Box)
      box.shape.should == "square"
      box.key.should == "square"
      box.instance_variable_get(:@robject).should_not be_nil
      box.should_not be_new_record
    end

    it "should find the first document using the first key with the bucket's keys" do
      box  = Box.new
      keys = ['some_boxes_key']
      Box.stub!(:find).and_return(box)
      @bucket.stub!(:keys).and_return(keys)
      @bucket.should_receive(:keys)
      keys.should_receive(:first)
      Box.first.should == box
    end

    it "should use find! when using first!" do
      box = Box.new
      Box.stub!(:find!).and_return(box)
      @bucket.stub!(:keys).and_return(['key'])
      Box.first!.should == box
    end

    it "should not raise an exception when finding an existing document with find!" do
      lambda { Box.find!("square") }.should_not raise_error(Ripple::DocumentNotFound)
    end

    it "should put properties we don't know about into the attributes" do
      @plain.raw_data = '{"non_existent_property":"some_value"}'
      box = Box.find("square")
      box[:non_existent_property].should == "some_value"
      box.should_not respond_to(:non_existent_property)
    end

    it "should return the document when calling find!" do
      box = Box.find!("square")
      box.should be_kind_of(Box)
    end

    it "should return nil when no object exists at that key" do
      @bucket.should_receive(:get).with("square", {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, "404 not found"))
      box = Box.find("square")
      box.should be_nil
    end

    it "should raise DocumentNotFound when using find! if no object exists at that key" do
      @bucket.should_receive(:get).with("square", {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, "404 not found"))
      lambda { Box.find!("square") }.should raise_error(Ripple::DocumentNotFound, "Couldn't find document with key: square")
    end

    it "should re-raise the failed request exception if not a 404" do
      @bucket.should_receive(:get).with("square", {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 500, {}, "500 internal server error"))
      lambda { Box.find("square") }.should raise_error(Riak::FailedRequest)
    end

    it "should handle a key with a nil value" do
      @plain.raw_data = nil
      @plain.data = nil
      box = Box.find("square")
      box.should be_kind_of(Box)
      box.key.should == "square"
    end
  end

  describe "finding multiple documents" do
    it "should find many documents with a single mapreduce query" do
      square = stub(:square)
      rectangle = stub(:rectangle)
      Box.should_receive(:find_many).once.with("square", "rectangle").and_return([square, rectangle])
      boxes = Box.find("square", "rectangle")
      boxes.should == [square, rectangle]
    end

    it "should find documents separately when streaming" do
      square = stub(:square)
      rectangle = stub(:rectangle)
      Box.should_receive(:find_one).with("square").and_return(square)
      Box.should_receive(:find_one).with("rectangle").and_return(rectangle)
      boxes = []
      Box.find("square", "rectangle") {|box| boxes << box}
      boxes.should == [square, rectangle]
    end

    describe "when using find with missing keys" do
      describe "streaming" do
        before :each do
          @bucket.should_receive(:get).with("square", {}).and_return(@plain)
          @bucket.should_receive(:get).with("rectangle", {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, "404 not found"))
        end

        it "should return nil for documents that no longer exist when streaming" do
          boxes = []
          Box.find("square", "rectangle") {|box| boxes << box}
          boxes.should have(2).items
          boxes.first.shape.should == "square"
          boxes.last.should be_nil
        end
      end

      describe "mapreduce" do
        it "should return nil for missing documents when using mapreduce" do
          @backend.stub(:mapred)
          Riak::RObject.stub(:load_from_mapreduce).and_return([@plain, @not_found])
          boxes = Box.find("square", "rectangle")
          boxes.should have(2).items
          boxes.first.shape.should == "square"
          boxes.last.should be_nil
        end

        it "should raise Ripple::DocumentNotFound when calling find! if some of the documents do not exist" do
          @backend.stub(:mapred)
          Riak::RObject.stub(:load_from_mapreduce).and_return([@plain, @not_found])
          lambda { Box.find!("square", "rectangle") }.should raise_error(Ripple::DocumentNotFound, "Couldn't find documents with keys: rectangle")
        end
      end
    end
  end

  describe "finding all documents in the bucket" do
    it "should load all objects in the bucket" do
      @bucket.stub(:keys).and_return(["square", "rectangle"])
      Riak::RObject.stub(:load_from_mapreduce).and_return([@plain, @cb])
      mapreduce = stub(:mapreduce).as_null_object
      Riak::MapReduce.stub(:new => mapreduce)
      boxes = Box.all
      boxes.should have(2).items
      boxes.first.shape.should == "square"
      boxes.last.shape.should == "rectangle"
    end

    it "should exclude objects that are not found" do
      @bucket.should_receive(:keys).and_return(["square", "rectangle"])
      Riak::RObject.stub(:load_from_mapreduce).and_return([@plain, @not_found])
      mapreduce = stub(:mapreduce).as_null_object
      Riak::MapReduce.stub(:new => mapreduce)
      boxes = Box.all
      boxes.should have(1).item
      boxes.first.shape.should == "square"
    end

    it "should yield found objects to the passed block, excluding missing objects, and return an empty array" do
      @bucket.should_receive(:keys).and_yield(["square"]).and_yield(["rectangle"])
      @bucket.should_receive(:get).with("square", {}).and_return(@plain)
      @bucket.should_receive(:get).with("rectangle", {}).and_raise(Riak::HTTPFailedRequest.new(:get, 200, 404, {}, "404 not found"))
      @block = mock()
      @block.should_receive(:ping).once
      Box.all do |box|
        @block.ping
        ["square", "rectangle"].should include(box.shape)
      end.should == []
    end

    it "fetches multiple documents when using #all without block" do
      @bucket.stub(:keys).and_return([stub(:key)])

      Box.should_receive(:find_many).and_return []

      Box.all
    end

    it "fetches documents separately when using #all with block" do
      keys = stub(:keys)
      keys.stub(:each).and_yield(stub(:key))
      @bucket.stub(:keys).and_yield(keys)

      Box.should_receive(:find_one).and_return(stub(:one_found))

      Box.all {|box| }
    end
  end

  describe "single-bucket inheritance" do
    it "should instantiate as the proper type if defined in the document" do
      @cb.raw_data = '{"shape":"rectangle", "_type":"CardboardBox"}'
      mapreduce = stub(:mapreduce).as_null_object
      Riak::MapReduce.stub(:new => mapreduce)
      Riak::RObject.stub(:load_from_mapreduce).and_return([@plain, @cb])
      boxes = Box.find("square", "rectangle")
      boxes.should have(2).items
      boxes.first.class.should == Box
      boxes.last.should be_kind_of(CardboardBox)
    end
  end

  describe '#find_many finding multiple documents' do
    class ExampleModel
      include Ripple::Document
    end

    it "returns an empty array if no keys given" do
      ExampleModel.send(:find_many).should == []
    end

    it "initializes a mapreduce" do
      client = stub(:client).as_null_object
      Ripple.stub(client: client)

      Riak::MapReduce.should_receive(:new).with(client).and_return(stub.as_null_object)

      ExampleModel.send(:find_many, 'key-1')
    end

    it "adds all the keys" do
      mapreduce = stub(:mapreduce, :run => []).as_null_object
      Riak::MapReduce.stub(new: mapreduce)

      mapreduce.should_receive(:add).with("example_models", 'key-1').and_return(mapreduce)
      mapreduce.should_receive(:add).with("example_models", 'key-2').and_return(mapreduce)

      ExampleModel.send(:find_many, 'key-1', 'key-2')
    end

    it "adds the map phase" do
      mapreduce = stub(:mapreduce, :run => [])
      Riak::MapReduce.stub(new: mapreduce)
      mapreduce.stub(add: mapreduce)

      mapreduce.should_receive(:map).with('function(value) {return [value]}', keep: true).and_return(stub.as_null_object)

      ExampleModel.send(:find_many, 'key-1', 'key-2')
    end

    it "instantiates the model" do
      model = stub(:model, key: 'key-1').as_null_object
      robject = stub(:robject)
      mapreduce = stub(:mapreduce, :run => [robject]).as_null_object
      Riak::MapReduce.stub(new: mapreduce)
      Riak::RObject.stub(:load_from_mapreduce).and_return([robject])
      ExampleModel.should_receive(:instantiate).with(robject).and_return(model)

      ExampleModel.send(:find_many, 'key-1')
    end

    it "returns the model" do
      model = stub(:model, key: 'key-1').as_null_object
      mapreduce = stub(:mapreduce, :run => [model]).as_null_object
      Riak::MapReduce.stub(new: mapreduce)
      ExampleModel.stub(:instantiate => model)

      ExampleModel.send(:find_many, 'key-1').should == [model]
    end

    it "returns the models in the same order as the given keys" do
      model1 = stub(:model1, key: 'key-1')
      model2 = stub(:model2, key: 'key-2')
      mapreduce = stub(:mapreduce).as_null_object
      Riak::MapReduce.stub(new: mapreduce)
      Riak::RObject.stub(:load_from_mapreduce).and_return([stub(:robject1), stub(:robject2)])

      ExampleModel.should_receive(:instantiate).and_return(model2, model1)

      ExampleModel.send(:find_many, 'key-1', 'key-2').should == [model1, model2]
    end
  end
end
