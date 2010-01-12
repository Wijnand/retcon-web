require 'spec_helper'

describe Include do
  before(:each) do
    @valid_attributes = {
      :path => "/backup/mysql",
      :profile_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    i = Include.new(@valid_attributes)
    i.valid?.should be true
  end
  
  it "should not allow missing paths" do
    i = Include.new(@valid_attributes)
    i.path = nil
    i.valid?.should be false
  end
  
  it "should not allow missing profiles" do
    i = Include.new(@valid_attributes)
    i.profile_id = nil
    i.valid?.should be false
  end
end
