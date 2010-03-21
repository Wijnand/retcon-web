require 'spec_helper'
require 'time'

describe Server do
  before(:each) do
  
  end

  it "should create a new instance given valid attributes" do
    s = Factory.build(:server)
    s.valid?.should be true
  end
  
  it "should not be valid when no hostname is given" do
    s = Factory.build(:server)
    s.hostname = nil
    s.valid?.should be false
  end
  
  it "should not be valid when no interval is given" do
    s = Factory.build(:server)
    s.interval_hours = nil
    s.valid?.should be false
  end
  
  it "should not be valid when no ssh_port is given" do
    s = Factory.build(:server)
    s.ssh_port = nil
    s.valid?.should be false
  end
  
  it "should not be valid when no keep_snapshots is given" do
    s = Factory.build(:server)
    s.keep_snapshots = nil
    s.valid?.should be false
  end
  
  it "should not accept impossible hours" do
    s = Factory.build(:server)
    s.window_start = 25
    s.valid?.should be false
    s.window_start = 1
    s.window_stop = 25
    s.valid?.should be false
    s.window_stop = 2
    s.valid?.should be true
  end
  
  it "should be valid when the other attributes are not given" do
    s = Factory.build(:server)
    s.connect_to = nil
    s.enabled = nil
    s.backup_server_id = nil
    s.valid?.should be true
  end
  
  it "should provide a instance method to determine valid backup servers" do
    s1 = Factory.build(:server, :connect_to => '127.0.0.1')
    s2 = Factory.build(:server)
    s2.connect_to = nil
    BackupServer.should_receive(:available_for).with(s1.connect_to)
    BackupServer.should_receive(:available_for).with(s2.hostname)
    s1.possible_backup_servers
    s2.possible_backup_servers
  end
  
  it "should provide a to_s method" do
    s = Factory.build(:server)
    s.to_s.should == s.hostname
  end
  
  it "should not backup when backups are disabled" do
    server = Factory.build(:server, :enabled => false, 
                                    :interval_hours => 1)
    server.should_backup?.should be false
  end
  
  it "should not backup when no backup server is selected" do
    server = Factory.build(:server, :enabled => true, :backup_server => nil, 
                                    :interval_hours => 1)
    server.should_backup?.should be false
  end
  
  it "should know if a backup is running" do
    s1 = Factory.build(:server)
    s1.backup_running?.should be false
    s2 = Factory.build(:server)
    s2.backup_running?.should be true
  end
  
  it "should not backup when a backup is already running" do
    s = Factory.build(:server)
    s.backup_running?.should be true
    s.should_backup?.should be false
  end
  
  it "should always be in the backup window when no start or end is given" do
    server = Factory.build(:server)
    server.in_backup_window?.should be true
    server.window_start = 0
    server.in_backup_window?.should be true
    server.window_start = nil
    server.window_stop = 0
    server.in_backup_window?.should be true
  end
  
  it "should know when it's not in the window" do
    server_one_hour_window = Factory.build(:server)
    server_one_hour_window.window_start = 1
    server_one_hour_window.window_stop = 2
    Time.should_receive(:new).and_return(Time.parse("03:00"))
    server_one_hour_window.in_backup_window?.should be false
    
    server_23_hour_window = Factory.build(:server)
    server_23_hour_window.window_start = 0
    server_23_hour_window.window_stop = 23
    Time.should_receive(:new).and_return(Time.parse("23:30"))
    server_23_hour_window.in_backup_window?.should be false
  end

  it "should know when it's in the window" do
    server = Factory.build(:server)
    server.window_start = 1
    server.window_stop = 2
    Time.should_receive(:new).and_return(Time.parse("01:30"))
    server.in_backup_window?.should be true
    
    server.window_start = 0
    server.window_stop = 1
    Time.should_receive(:new).and_return(Time.parse("00:30"))
    server.in_backup_window?.should be true
    
    server.window_start = 23
    server.window_stop = 0
    Time.should_receive(:new).and_return(Time.parse("23:30"))
    server.in_backup_window?.should be true
  end
  
  it "should know when its past the interval" do
    s = Factory.build(:server, :last_started => (Time.new - (2 * 3600)), :interval_hours => 1)
    s.interval_passed?.should be true
    
    s.interval_hours = 3
    s.interval_passed?.should be false
  end
  
  it "should know when to backup" do
    s = Factory.build(:server)
    s.interval_hours = 1
    s.should_backup?.should be true
    
    # already running
    s.interval_hours = 24
    s.should_backup?.should be false
    
    # already did one in the window
    s.interval_hours = 24
    s.should_backup?.should be false
    
    # The most common case
    s.window_start = nil
    s.window_stop = nil
    s.interval_hours = 24
    s.should_backup?.should be true
  end
  
  it "should know the excludes inherited trough the profiles" do
    s = Factory.build(:server) # we need one server
    p1 = Factory.build(:profile, :name => 'linux') # profile one
    p2 = Factory.build(:profile, :name => 'standard') # and another one
    p1.excludes << Factory.build(:exclude, :path => '/') # exclude one
    p2.excludes << Factory.build(:exclude, :path => '/var/log') # second exclude
    s.profiles << p1
    s.profiles << p2
    s.excludes.size.should == 2
  end
  
  it "should know the includes inherited trough the profiles" do
    s = Factory.build(:server) # we need one server
    p1 = Factory.build(:profile, :name => 'linux') # profile one
    p2 = Factory.build(:profile, :name => 'standard') # and another one
    p1.includes << Factory.build(:include, :path => '/') # include one
    p2.includes << Factory.build(:include, :path => '/var/log') # second include
    s.profiles << p1
    s.profiles << p2
    s.includes.size.should == 2
  end
  
  it "should compile the list of excludes to valid rsync args" do
    s = Factory.build(:server) # we need one server
    p1 = Factory.build(:profile, :name => 'linux') # profile one
    p2 = Factory.build(:profile, :name => 'standard') # and another one
    p1.excludes << Factory.build(:exclude, :path => '/') # include one
    p2.excludes << Factory.build(:exclude, :path => '/var/log') # second include
    s.profiles << p1
    s.profiles << p2
    
    s.rsync_excludes.should == '--exclude=/ --exclude=/var/log'
  end
  
  it "should compile the list of includes to valid rsync args" do
    s = Factory.build(:server) # we need one server
    p1 = Factory.build(:profile, :name => 'linux') # profile one
    p2 = Factory.build(:profile, :name => 'standard') # and another one
    p1.includes << Factory.build(:include, :path => '/') # include one
    p2.includes << Factory.build(:include, :path => '/var/log') # second include
    s.profiles << p1
    s.profiles << p2

    s.rsync_includes.should == '--include=/ --include=/var/log'
  end
  
  it "should use the path of the first profile as start dir" do
    s = Factory.build(:server) # we need one server
    p1 = Factory.build(:profile, :name => 'linux', :path => '/') # profile one
    p2 = Factory.build(:profile, :name => 'standard', :path => '/verybogus') # and another one
    s.profiles << p1
    s.profiles << p2
    s.startdir.should == '/'
  end
end
