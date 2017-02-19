require 'spec_helper'

describe Ripple::Associations::OneStoredKeyProxy do
  # require 'support/models/transactions'
  # require 'support/models/family'

  before :each do
    @account = Account.new {|e| e.key = "accounty" }
    @other_account = Account.new{|e| e.key = "ickycount" }
    @transaction = Transaction.new{|e| e.key = "transacty" }
  end

  it "should be blank before the associated document is set" do
    @transaction.account.should_not be_present
  end

  it "should accept a single document" do
    lambda { @transaction.account = @account }.should_not raise_error
  end

  it "should set the key when assigning" do
    @transaction.account = @account
    @transaction.account_key.should == "accounty"
  end

  it "should return the assigned document when assigning" do
    ret = (@transaction.account = @account)
    ret.should == @account
  end

  it "should find the associated document when accessing" do
    @transaction.account_key = "accounty"
    Account.should_receive(:find).with("accounty").and_return(@account)
    @transaction.account.should be_present
  end

  it "should return nil immediately if the association link is missing" do
    @transaction.account_key.should be_nil
    @transaction.account.should be_nil
  end

  it "should replace associated document with a new one" do
    @transaction.account = @account
    @transaction.account = @other_account
    @transaction.account.should == @other_account
    @transaction.account_key.should == "ickycount"
  end

  it "should replace the associated document with the target of the proxy" do
    other_transaction = Transaction.new {|e| e.key = "ickytrans" }
    other_transaction.account = @other_account

    @transaction.account = other_transaction.account
    @transaction.account.should == @other_account
  end

  it "refuses assigning a proxy if its target is the wrong type" do
    parent = Parent.new{|e| e.child = Child.new}
    lambda { @transaction.account = parent.child }.should raise_error
  end

  it "should refuse assigning a document of the wrong type" do
    lambda { @transaction.account = @transaction }.should raise_error
  end

  it "should nil out the association if nil is assigned" do
    @transaction.account = @account
    @transaction.account = nil
    @transaction.account.should be_nil
    @transaction.account_key.should be_nil
  end

  context "Foreign key associations" do
    before do
      @president = User.create(email: 'president@internet.com')
    end

    after do
      Country.destroy_all
      User.destroy_all
    end

    it "should accept a foreign key to create an association" do
      country = Country.create(name: 'Internet', president_user_id: @president.key)

      country.president.should == @president
      # TODO: Write this assert on OneInverseProxy test file
      @president.president_of.should == country
    end

    it "should update foreign key value when updates the association" do
      country = Country.create(name: 'Internet')
      country.president = @president

      country.president_user_id.should == @president.key
    end
  end
end
