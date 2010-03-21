require 'spec_helper'

describe BackupJob do
  it "should build a valid rsync command line" do
    s = Factory.build(:server, :hostname => 'server1.example.com')
    p = Factory.build(:profile, :name => 'linux')
    p.includes << Factory.build(:include, :path => '/')
    p.excludes << Factory.build(:exclude, :path => '/backup')
    s.profiles << p
    j = Factory.build(:backup_job, :server => s)
    j.to_rsync.should == "/usr/bin/pfexec rsync --stats -aHRW --timeout=600 --delete-excluded --exclude=.zfs -e 'ssh -c arcfour -p 22' --include=/ --exclude=/backup --log-file=/tmp/server1.example.com_debug root@server1.example.com:/ /backup/server1.example.com/"
  end
  
  it "should have a class method to convert exit statusses to a string representation" do
    job = Factory(:backup_job)
    job.code_to_success(0).should == 'OK'
    job.code_to_success(100).should == 'UNKNOWN'
    job.code_to_success(1).should == 'FAIL'
    job.code_to_success(25).should == 'PARTIAL'
  end
  
  it "should create commands with a specific label" do
    job = Factory(:backup_job)
    job.run_command('ls', 'listing')
    job.commands.size.should be 1
    job.commands.last.label.should == 'listing'
    job.commands.last.command.should == 'ls'
  end
  
  it "should create commands for the right user" do
    job = Factory(:backup_job)
    job.run_command('ls', 'listing')
    job.commands.last.user.should == job.backup_server.user
  end
  
  it "should pull the database for commands to pick up and run the callback" do
    job = Factory(:backup_job)
    command = Factory(:command, :backup_job => job)
    job.should_receive(:run_callback).once.with(command)
    job.wakeup
  end
  
  it "it should not run the callback when the command has no exitstatus" do
    job = Factory(:backup_job)
    command = Factory(:command, :backup_job => job, :exitstatus => nil)
    job.should_not_receive(:run_callback).with(command)
    job.wakeup
  end
  
  it "should call the right method when being called back" do
    job = Factory(:backup_job)
    command = Factory(:command, :label => 'snapshot')
    job.should_receive(:after_snapshot).with(command)
    job.run_callback(command)
  end
  
  it "should parse the rest of the label as command args" do
    job = Factory(:backup_job)
    command = Factory(:command, :label => 'rsync 1')
    job.should_receive(:after_rsync).with(command, '1')
    job.run_callback(command)
  end
  
  it "should prepare the filesystem when it starts running and set its status to running" do
    job = Factory(:backup_job, :status => 'queued')
    job.should_receive(:prepare_fs)
    job.run
    job.status.should == 'running'
    job.finished.should == false
  end
  
  it "prepare_fs should ask if the filesystem exists" do
    job = Factory(:backup_job)
    job.should_receive(:run_command).with("/sbin/zfs list #{job.fs}", "fs_exists")
    job.prepare_fs
  end
  
  it "should start the rsyncs if the filesystem exists" do
    job =  Factory(:backup_job)
    command = Factory(:command, :exitstatus => 0)
    job.should_receive(:start_rsyncs)
    job.after_fs_exists(command)
  end
  
  it "should give out an order to create a filesystem if it does not exist" do
    job =  Factory(:backup_job)
    command = Factory(:command, :exitstatus => 1)
    job.should_receive(:run_command).with("/bin/pfexec /sbin/zfs create #{job.fs}", "create_fs")
    job.after_fs_exists(command)
  end
  
  it "should check again after filesystem creation" do
    job =  Factory(:backup_job)
    command = Factory(:command, :exitstatus => 0)
    job.should_receive(:run_command).with("/sbin/zfs list #{job.fs}", "fs_exists_confirm")
    job.after_create_fs(command)
  end
  
  it "should fail when the filesystem could not be created" do
    job =  Factory(:backup_job)
    command = Factory(:command, :exitstatus => 1)
    job.after_create_fs(command)
    job.status.should == 'Unable to create filesystem'
    job.finished.should == true
  end
  
  it "should fail if the filesystem confimation fails" do
    job =  Factory(:backup_job)
    command = Factory(:command, :exitstatus => 1)
    job.after_fs_exists_confirm(command)
    job.status.should == 'Unable to create filesystem'
    job.finished.should == true
  end
  
  it "should start the rsyncs when the confirmation is positive" do
    job =  Factory(:backup_job)
    command = Factory(:command, :exitstatus => 0)
    job.should_receive(:start_rsyncs)
    job.after_fs_exists_confirm(command)
  end
  
  it "should create a rsync command" do
    job =  Factory(:backup_job)
    job.stub(:to_rsync).and_return('stub_for_rsync')
    job.should_receive(:run_command).with('stub_for_rsync', "rsync")
    job.start_rsyncs
  end
  
  it "should create a snapshot after the rsync and update its status" do
    job = Factory(:backup_job)
    command = Factory(:command, :exitstatus => 0)
    job.should_receive(:run_command).with("/bin/pfexec /sbin/zfs snapshot #{job.fs}@#{job.updated_at.to_i}", "snapshot")
    job.after_rsync(command)
    job.status.should == 'OK'
  end
  
  it "should ask for the disk usage after the snapshot" do
    job = Factory(:backup_job)
    command = Factory(:command, :exitstatus => 0)
    job.should_receive(:run_command).with("/sbin/zfs get -Hp #{job.fs} | /usr/gnu/bin/awk '{print $3}'", "diskusage")
    job.after_snapshot(command)
  end
  
  it "should update the disk usage" do
    job = Factory(:backup_job)
    command = Factory(:command, :exitstatus => 0, :output => '11')
    job.after_diskusage(command)
    job.server.usage.should == 11
    job.finished.should == true
  end
end