require 'spec_helper'

describe Exclude do
  before(:each) do
    @valid_attributes = {
      :path => "/backup",
      :profile_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    e = Exclude.new(@valid_attributes)
    e.valid?.should be true
  end
  
  it "should not be valid when no path is given" do
    e = Exclude.new(@valid_attributes)
    e.path = nil
    e.valid?.should be false
  end
  
  it "should not be valid when no profile is given" do
    e = Exclude.new(@valid_attributes)
    e.profile_id = nil
    e.valid?.should be false
  end
end
