require 'spec_helper'

describe BackupServer do
  before(:each) do
    @valid_attributes = {
      :hostname => "backup3",
      :zpool => "backup",
      :max_backups => 1
    }
    BackupServer.destroy_all
    BackupServer.create!(:hostname => 'backup1', :zpool => 'backup', :max_backups => 10)
  end

  it "should create a new instance given valid attributes" do
    b = BackupServer.new(@valid_attributes)
    b.valid?.should be true
  end
  
  it "should not save when no hostname is given" do
    b = BackupServer.new(@valid_attributes)
    b.hostname = nil 
    b.valid?.should be false
  end
  
  it "should not save when no zpool is given" do
    b = BackupServer.new(@valid_attributes)
    b.zpool = nil 
    b.valid?.should be false
  end
  
  it "should not save when no max_backups is given" do
    b = BackupServer.new(@valid_attributes)
    b.max_backups = nil 
    b.valid?.should be false
  end
  
  it "should have a to_s method" do
    b = BackupServer.new(@valid_attributes)
    b.to_s.should == 'backup3'
  end
  
  it "should have a way to call nanite jobs for a specific backup server" do
    b = BackupServer.new(@valid_attributes)
    Nanite.should_receive(:request).once.with("method", "arg", :target => b.hostname).and_yield("the result")
    b.send(:do_nanite, 'method', 'arg')
  end
  
  it "should be able to query using nanite" do
    Nanite.should_receive(:request).once.with("command", "arg", :selector => :all).and_yield(
           {'nanite-backup1' => 'my result', 'nanite-backup2' => 'other result'})
    list = BackupServer.nanite_query("command", "arg")
    list['backup1'].should == "my result"
  end
  
  it "should select valid backup servers for a given server" do
    Nanite.should_receive(:request).once.with("/info/in_subnet?", "localhost", :selector => :all).and_yield(
           {'nanite-backup1' => true, 'nanite-backup2' => false})
    available = BackupServer.available_for("localhost")
    available.should be_instance_of Array
    available.size.should be 1
    available[0].hostname.should == 'backup1'
  end
end
