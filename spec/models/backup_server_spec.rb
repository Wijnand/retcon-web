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
    b.stub(:nanites).and_return({"#{b.hostname}" => 'something'})
    Nanite.should_receive(:request).once.with("method", "arg", :target => "nanite-#{b.hostname}").and_yield("the result")
    b.send(:do_nanite, 'method', 'arg')
  end

  it "should be able to query using nanite" do
    BackupServer.stub(:nanites).and_return({'backup2' => 'something', 'backup1' => 'something'})
    Nanite.stub(:request).once.with("command", "arg", :selector => :all).and_yield(
           {'backup1' => 'my result', 'backup2' => 'other result'})
    list = BackupServer.nanite_query("command", "arg")
    list['backup1'].should == "my result"
  end

  it "should select valid backup servers for a given server" do
    backup1 = Factory(:backup_server)
    backup2 = Factory(:backup_server)
    BackupServer.stub(:nanites).and_return({"#{backup1.hostname}" => 'something',
                                                      "#{backup2.hostname}" => 'something'})
    Nanite.stub(:request).with("/info/in_subnet?", "localhost", :selector => :all).and_yield(
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
  
  it "should should take the already running backups into account" do
    b = Factory(:backup_server, :max_backups => 3)
    s1 = Factory(:server)
    s2 = Factory(:server)
    s3 = Factory(:server)
    job1 = Factory(:backup_job, :server => s1, :backup_server => b, :status => 'running')
    job2 = Factory(:backup_job, :server => s2, :backup_server => b, :status => 'running')
    job3 = Factory(:backup_job, :server => s3, :backup_server => b, :status => 'queued')
    job4 = Factory(:backup_job, :server => s3, :backup_server => b, :status => 'queued')
    b.queued_backups.size.should == 2
    b.next_queued.size.should == 1
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
  
  it "should only start backup jobs with at most next_queued" do
    setup_valid
    @backupserver.stub(:online?).and_return(true)
    @backupserver.should_receive(:run_backup_job).with @backupserver.backup_jobs[0]
    @backupserver.should_receive(:run_backup_job).with @backupserver.backup_jobs[1]
    @backupserver.should_not_receive(:run_backup_job).with @backupserver.backup_jobs[2]
    @backupserver.start_queued
  end

  it "should not start the backup if the filesystem is ready" do
    setup_valid
    @job1.stub(:prepare_fs).and_return false
    @backupserver.should_not_receive(:start_rsync)
    @backupserver.run_backup_job @job1
    @job1.status.should == 'Filesystem preparation failed'
  end
  
  it "should start the backup if the filesystem is ready" do
    setup_valid
    @job1.stub(:prepare_fs).and_return true
    @backupserver.should_receive(:start_rsync)
    @backupserver.run_backup_job @job1
    @job1.status.should == 'running'
  end
  
  it "should update the last_started field of the server" do
    setup_valid
    now = Time.new
    Time.stub(:new).and_return(now)
    @job1.stub(:prepare_fs).and_return true
    @backupserver.should_receive(:start_rsync)
    @backupserver.run_backup_job @job1
    @server1.last_started.should == now
  end
  it "should send a nanite command with the rsync line" do
    setup_valid
    Nanite.should_receive(:request).with("/command/syscmd", @job1.to_rsync, 
           :target => "nanite-#{@backupserver.hostname}")
    @backupserver.start_rsync @job1
  end
  
  it "should process the result after a backup" do
    setup_valid
    result = [0, 'done']
    Nanite.should_receive(:request).with("/command/syscmd", @job1.to_rsync, 
           :target => "nanite-#{@backupserver.hostname}").and_yield("nanite-#{@backupserver.hostname}" => result)
    @backupserver.should_receive(:handle_backup_result).with(result, @job1)
    @backupserver.start_rsync @job1
  end
  
  it "handle_backup_result should create a snapshot when the backup is OK" do
    setup_valid
    result = [0,'done']
    BackupJob.stub(:code_to_success).and_return("OK")
    @backupserver.should_receive(:create_snapshot).with(@job1)
    @backupserver.handle_backup_result result, @job1
    @job1.status.should == 'OK'
  end
  
  it "handle_backup_result should not create a snapshot when the backup failed" do
    setup_valid
    result = [0,'done']
    BackupJob.stub(:code_to_success).and_return("FAILED")
    @backupserver.should_not_receive(:create_snapshot).with(@job1)
    @backupserver.handle_backup_result result, @job1
    @job1.status.should == 'FAILED'
  end
  
  it "handle_backup_result should create a snapshot when the backup is partial" do
    setup_valid
    result = [0,'done']
    BackupJob.stub(:code_to_success).and_return("PARTIAL")
    @backupserver.should_receive(:create_snapshot).with(@job1)
    @backupserver.handle_backup_result result, @job1
    @job1.status.should == 'PARTIAL'
  end
  
  it "handle_backup_result should create a snapshot when the backup status is unknown" do
    setup_valid
    result = [0,'done']
    BackupJob.stub(:code_to_success).and_return("UNKNOWN")
    @backupserver.should_receive(:create_snapshot).with(@job1)
    @backupserver.handle_backup_result result, @job1
    @job1.status.should == 'UNKNOWN'
  end
  
  it "should know how to send a snapshot command" do
    setup_valid
    now = Time.new
    Nanite.should_receive(:push).with("/command/syscmd", "/usr/bin/pfexec /usr/sbin/zfs snapshot #{@job1.fs}@#{now.to_i}", 
           :target => "nanite-#{@backupserver.hostname}")
    @backupserver.create_snapshot @job1
  end
end
