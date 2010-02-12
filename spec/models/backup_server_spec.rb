require 'spec_helper'

describe BackupServer do
  before(:each) do

  end

  it "should create a new instance given valid attributes" do
    b = Factory.build(:backup_server)
    b.valid?.should be true
  end
  
  it "should not save when no hostname is given" do
    b = Factory.build(:backup_server, :hostname => nil)
    b.valid?.should be false
  end
  
  it "should not save when no zpool is given" do
    b = Factory.build(:backup_server, :zpool => nil)    
    b.valid?.should be false
  end
  
  it "should not save when no max_backups is given" do
    b = Factory.build(:backup_server, :max_backups => nil)
    b.valid?.should be false
  end
  
  it "should have a to_s method" do
    b = Factory.build(:backup_server)
    b.to_s.should == b.hostname
  end
  
  it "should have a way to call nanite jobs for a specific backup server" do
    b = Factory.build(:backup_server)
    b.should_receive(:nanites).and_return({"#{b.hostname}" => 'something'})
    Nanite.should_receive(:request).once.with("method", "arg", :target => "nanite-#{b.hostname}").and_yield("the result")
    b.send(:do_nanite, 'method', 'arg')
  end
  
  it "should be able to query using nanite" do
    BackupServer.should_receive(:nanites).and_return({'backup2' => 'something', 'backup1' => 'something'})
    Nanite.should_receive(:request).once.with("command", "arg", :selector => :all).and_yield(
           {'backup1' => 'my result', 'backup2' => 'other result'})
    list = BackupServer.nanite_query("command", "arg")
    list['backup1'].should == "my result"
  end
  
  it "should select valid backup servers for a given server" do
    backup1 = Factory(:backup_server)
    backup2 = Factory(:backup_server)
    BackupServer.should_receive(:nanites).and_return({"#{backup1.hostname}" => 'something', 
                                                      "#{backup2.hostname}" => 'something'})
    Nanite.should_receive(:request).once.with("/info/in_subnet?", "localhost", :selector => :all).and_yield(
           {"#{backup1.hostname}" => true, "#{backup2.hostname}" => false})
    available = BackupServer.available_for("localhost")
    available.should be_instance_of Array
    available.size.should be 2
    available[0].in_subnet.should == true
    available[1].in_subnet.should == false
  end
  
  it "should know if it's online" do
    backup1 = Factory(:backup_server)
    backup2 = Factory(:backup_server)
    BackupServer.should_receive(:nanites).twice.and_return({"#{backup1.hostname}" => 'something'}) 
    backup1.online?.should be true
    backup2.online?.should be false
  end
end
