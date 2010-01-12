require 'spec_helper'

describe Profile do
  before(:each) do
    @valid_attributes = {
      :name => "linux",
      :path => "/"
    }
  end

  it "should create a new instance given valid attributes" do
    p = Profile.new(@valid_attributes)
    p.valid?.should be true
    p.save
  end
  
  it "should not allow a missing path" do
    p = Profile.new(@valid_attributes)
    p.path = nil
    p.valid?.should be false
  end
  
  it "should not allow a missing name" do
    p = Profile.new(@valid_attributes)
    p.name = nil
    p.valid?.should be false
  end
end
