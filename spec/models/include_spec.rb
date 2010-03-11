require 'spec_helper'

describe Include do

  it "should create a new instance given valid attributes" do
    i = Factory.build :include
    i.valid?.should be true
  end
  
  it "should not allow missing paths" do
    i = Factory.build :include, :path => nil
    i.valid?.should be false
  end
  
  it "should not allow missing profiles" do
    i = Factory.build :include, :profile_id => nil
    i.valid?.should be false
  end
  
  it "should respond to to_s" do
    i = Factory.build :include, :path => '/'
    i.to_s.should == '/'
  end
end
