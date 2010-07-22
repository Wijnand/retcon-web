require 'spec_helper'

describe Profile do
  before do
    Profile.destroy_all
  end

  it "should create a new instance given valid attributes" do
    p = Factory.build(:profile)
    p.valid?.should be true
  end
  
  it "should not allow a missing name" do
    p = Factory.build(:profile, :name => nil)
    p.valid?.should be false
  end

  it "should be possible to create an exclusive profile" do
    p = Factory.build(:profile, :exclusive => true)
    p.valid?.should be true
  end

  it "should have a class method to fetch all public profiles" do
    p1 = Factory(:profile, :exclusive => true)
    p2 = Factory(:profile)
    results = Profile.public
    results.count.should == 1
    results[0].exclusive.should == false
  end

  it "should only allow to attach an exclusive profile to one server" do
    s1 = Factory(:server)
    s2 = Factory(:server)
    p = Factory.build(:profile, :exclusive => true)
    p.servers << s1
    p.valid?.should == true
    p.servers << s2
    p.valid?.should == false
  end
end
