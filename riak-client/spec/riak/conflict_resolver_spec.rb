require 'spec_helper'

describe Riak::Util::ConflictResolver do
  let(:sibling1) { mock("Sibling1", :data => {:name => "Foo", :size => 5}) }
  let(:sibling2) { mock("Sibling2", :data => {:name => "Bar", :size => 5}) }
  let(:sibling3) { mock("Sibling3", :data => {:name => "Baz", :size => 5}) }
  let(:robject)  { mock("Robject", :siblings => [sibling1, sibling2, sibling3])}

  subject { Riak::Util::ConflictResolver.new(robject) }

  describe "#conflicting" do
    it "should return a hash of keys to values that are not equal" do
      subject.conflicting.should == {:name => ["Foo", "Bar", "Baz"]}
    end
  end

  describe "#nonconflicting" do
    it "should return an attributes hash for equal values" do
      subject.nonconflicting.should == {:size => 5}
    end
  end
end