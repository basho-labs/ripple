# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
require File.expand_path("../../../spec_helper", __FILE__)

describe "Ripple Persistence" do
  require 'support/test_server'

  before :all do
    Object.module_eval do
      class Widget
        include Ripple::Document
        property :name, String
        property :size, Integer
      end
    end
  end

  before :each do
    @widget = Widget.new
  end

  it "should save an object to the riak database" do
    @widget.save
    @found = Widget.find(@widget.key)
    @found.should be_a(Widget)
  end

  it "should save attributes properly to riak" do
    @widget.attributes = {:name => 'Sprocket', :size => 10}
    @widget.save
    @found = Widget.find(@widget.key)
    @found.name.should == 'Sprocket'
    @found.size.should == 10
  end

  context "when conflicts are found" do
    before(:all) do
      class Widget
        Widget.bucket.allow_mult = true

        def has_called_handle_conflict?
          @handle_conflict_called == true
        end

        def handle_conflict(robject)
          @handle_conflict_called = true
        end
      end
    end

    after(:all) do
      class Widget
        Widget.bucket.allow_mult = false
        undef has_called_handle_conflict?
        undef handle_conflict
      end
    end

    let(:reference_1) { Widget.create(:name => "Foo") }
    let(:reference_2) { Widget.find(reference_1.key)  }

    before do
      reference_1.name = "Fizz"
      reference_2.name = "Buzz"
      reference_1.save
      reference_2.save
      # the tests depend on this, but it's not what's being tested
      reference_2.robject.should be_conflict
    end

    describe '#handle_conflict' do
      it 'is called on find' do
        another_reference = Widget.find(reference_1.key)
        another_reference.should have_called_handle_conflict
      end

      it 'is called on reload' do
        reference_1.reload
        reference_1.should have_called_handle_conflict
      end

      context 'when undefined' do
        after(:each) do
          # Need this so destroy_all works later
          class Widget
            def handle_conflict(robject)
              @handle_conflict_called = true
            end
          end
        end

        it 'raises a NotImplementedError' do
          class Widget
            remove_method :handle_conflict
          end

          lambda { reference_1.reload }.should raise_error(NotImplementedError)
        end
      end
    end
  end

  after :each do
    Widget.destroy_all
  end

  after :all do
    Object.send(:remove_const, :Widget)
  end
  
end
