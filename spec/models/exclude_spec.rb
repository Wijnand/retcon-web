require 'spec_helper'

describe Exclude do

  it "should create a new instance given valid attributes" do
    e = Factory.build :exclude
    e.valid?.should be true
  end
  
  it "should not be valid when no path is given" do
    e = Factory.build :exclude, :path => nil
    e.valid?.should be false
  end
  
  it "should not be valid when no profile is given" do
    e = Factory.build :exclude, :profile_id => nil
    e.valid?.should be false
  end
end
