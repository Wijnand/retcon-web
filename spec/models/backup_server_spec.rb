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

  it "should know which servers it should backup" do
    b = Factory(:backup_server)
    s1 = Factory(:server, :backup_server => b)
    s2 = Factory(:server, :backup_server => b)
    s1.stub(:should_backup?).and_return false
    s2.stub(:should_backup?).and_return true
    b.stub(:servers).and_return [s1, s2]
    b.should_start.size.should == 1
    b.should_start[0].hostname.should == s2.hostname
  end
  
  it "should create a backup job for each server that should be backed up" do
    b = Factory(:backup_server)
    s1 = Factory(:server)
    s2 = Factory(:server)
    s3 = Factory(:server)
    b.stub(:should_start).and_return [s1, s3]
    BackupJob.should_receive(:create!).with(:backup_server => b, :server => s1, :status => 'queued')
    BackupJob.should_receive(:create!).with(:backup_server => b, :server => s3, :status => 'queued')
    b.queue_backups
  end
  
  it "should know how to retrieve queued backups with at most max_backups" do
    b = Factory(:backup_server, :max_backups => 2)
    job1 = Factory(:backup_job, :backup_server => b, :status => 'queued')
    job2 = Factory(:backup_job, :backup_server => b, :status => 'queued')
    job3 = Factory(:backup_job, :backup_server => b, :status => 'queued')
    b.queued_backups.size.should == 3
    b.next_queued.size.should == 2
  end
  
  it "should should take the already running backups into account" do
    b = Factory(:backup_server, :max_backups => 3)
    job1 = Factory(:backup_job, :backup_server => b, :status => 'running', :finished => false)
    job2 = Factory(:backup_job, :backup_server => b, :status => 'running', :finished => false)
    job3 = Factory(:backup_job, :backup_server => b, :status => 'queued')
    job4 = Factory(:backup_job, :backup_server => b, :status => 'queued')
    b.queued_backups.size.should == 2
    b.next_queued.size.should == 1
  end

  it "should know how many backups are running" do
    b = Factory(:backup_server)
    job1 = Factory(:backup_job, :backup_server => b, :status => 'running', :finished => false)
    job2 = Factory(:backup_job, :backup_server => b, :status => 'running', :finished => false)
    job3 = Factory(:backup_job, :backup_server => b, :status => 'running', :finished => false)
    b.running_backups.size.should == 3
  end
  
  it "should only start backup jobs with at most next_queued" do
    setup_valid
    @backupserver.stub(:next_queued).and_return [@job1, @job2]
    @job1.should_receive(:run)
    @job2.should_receive(:run)
    @job3.should_not_receive(:run)
    @backupserver.start_queued
  end
end
