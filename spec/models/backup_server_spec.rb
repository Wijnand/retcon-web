require 'spec_helper'

describe BackupServer do
  def setup_valid
    @backupserver = Factory(:backup_server, :max_backups => 2)
    @server1 = Factory(:server)
    @server2 = Factory(:server)
    @server3 = Factory(:server)
    @profile= Factory(:profile)
    @server1.profiles << @profile
    @server2.profiles << @profile
    @server3.profiles << @profile
    @job1 = Factory(:backup_job, :server => @server1, :backup_server => @backupserver, :status => 'queued')
    @job2 = Factory(:backup_job, :server => @server2, :backup_server => @backupserver, :status => 'queued')
    @job3 = Factory(:backup_job, :server => @server3, :backup_server => @backupserver, :status => 'queued')
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

  # very bad test since it actually calls the methods on Server instances
  it "should know which servers it should backup" do
    b = Factory(:backup_server)
    s1 = Factory(:server, :hostname => 'server1.example.com', :backup_server => b)
    s2 = Factory(:server, :hostname => 'server2.example.com', :backup_server => b,
                 :last_backup => Time.new - (3 * 3600), 
                 :last_started =>Time.new - ( 4 * 3600))
    s3 = Factory(:server, :hostname => 'server3.example.com', :backup_server => b)
    to_backup = b.should_start
    to_backup.size.should == 2
    to_backup[0].hostname.should == 'server1.example.com'
    to_backup[1].hostname.should == 'server3.example.com'
  end
  
  it "should create a backup job for each server that should be backed up" do
    b = Factory(:backup_server)
    s1 = Factory(:server, :hostname => 'server1.example.com', :backup_server => b)
    s2 = Factory(:server, :hostname => 'server2.example.com', :backup_server => b,
                 :last_backup => Time.new - (3 * 3600), 
                 :last_started =>Time.new - ( 4 * 3600))
    s3 = Factory(:server, :hostname => 'server3.example.com', :backup_server => b)
    BackupJob.should_receive(:create!).with(:backup_server => b, :server => s1, :status => 'queued')
    BackupJob.should_receive(:create!).with(:backup_server => b, :server => s3, :status => 'queued')
    b.queue_backups
  end
  
  it "should know how to retrieve queued backups with at most max_backups" do
    b = Factory(:backup_server, :max_backups => 2)
    s1 = Factory(:server)
    s2 = Factory(:server)
    s3 = Factory(:server)
    job1 = Factory(:backup_job, :server => s1, :backup_server => b, :status => 'queued')
    job2 = Factory(:backup_job, :server => s2, :backup_server => b, :status => 'queued')
    job3 = Factory(:backup_job, :server => s3, :backup_server => b, :status => 'queued')
    b.queued_backups.size.should == 3
    b.next_queued.size.should == 2
  end

  it "should know how many backups are running" do
    b = Factory(:backup_server)
    s1 = Factory(:server)
    s2 = Factory(:server)
    s3 = Factory(:server)
    job1 = Factory(:backup_job, :server => s1, :backup_server => b, :status => 'running')
    job2 = Factory(:backup_job, :server => s2, :backup_server => b, :status => 'running')
    job3 = Factory(:backup_job, :server => s3, :backup_server => b, :status => 'running')
    b.running_backups.size.should == 3
  end
  
  it "should start backups with the right rsync command" do
    setup_valid
    @backupserver.should_receive(:online?).and_return(true)
    Nanite.should_receive(:request).with('/command/syscmd', @job1.to_rsync, :target => "nanite-#{@backupserver.hostname}")
    Nanite.should_receive(:request).with('/command/syscmd', @job2.to_rsync, :target => "nanite-#{@backupserver.hostname}")
    Nanite.should_not_receive(:request).with('/command/syscmd', @job3.to_rsync, :target => "nanite-#{@backupserver.hostname}")
    @backupserver.run_queued
    @backupserver.backup_jobs[0].status.should == 'running'
    @backupserver.backup_jobs[1].status.should == 'running'
    @backupserver.backup_jobs[2].status.should == 'queued'
  end
end
