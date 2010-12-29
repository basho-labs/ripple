require 'spec_helper'

describe "Ripple::Document with a conflict" do
  require 'support/test_server'

  before :all do
    Object.module_eval do
      class Widget
        include Ripple::Document
        bucket.allow_mult = true

        property :name, String
        property :size, Integer
      end
    end
  end

  subject             { Widget.create            }
  let(:other_subject) { Widget.find(subject.key) }

  before do
    other_subject.name = 'Foo'
    subject.name = 'Bar'

    other_subject.size = 5
    subject.size = 5

    other_subject.save
    subject.save

    subject.reload
  end

  describe "#conflicts" do
    it "should have a conflict on name" do
      subject.conflicts['name'].sort.should == ['Bar', 'Foo']
    end

    it "should not have a conflict on size" do
      subject.conflicts.keys.should_not include('size')
    end
  end

  after :each do
    Widget.destroy_all
  end

  after :all do
    Object.send(:remove_const, :Widget)
  end
end