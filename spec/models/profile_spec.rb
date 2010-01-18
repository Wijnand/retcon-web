require 'spec_helper'

describe Profile do

  it "should create a new instance given valid attributes" do
    p = Factory.build(:profile)
    p.valid?.should be true
  end
  
  it "should not allow a missing path" do
    p = Factory.build(:profile, :path => nil)
    p.valid?.should be false
  end
  
  it "should not allow a missing name" do
    p = Factory.build(:profile, :name => nil)
    p.valid?.should be false
  end
end
