require 'spec_helper'

describe BackupJob do
  it "should build a valid main rsync command line" do
    s = Factory.build(:server, :hostname => 'server1.example.com')
    p = Factory.build(:profile, :name => 'linux')
    p.includes << Factory.build(:include, :path => '/')
    p.excludes << Factory.build(:exclude, :path => '/backup')
    p.splits << Factory.build(:split, :path => '/home')
    s.profiles << p
    j = Factory.build(:backup_job, :server => s)
    j.main_rsync.should == "/usr/bin/pfexec rsync --stats -aHRW --timeout=3600 --delete-excluded --exclude=.zfs -e 'ssh -c arcfour -p 22' --filter='protect /home' --include=/ --exclude=/home --exclude=/backup root@server1.example.com:/ /backup/server1.example.com/"
  end

  it "should store a list of rsyncs" do
    s = Factory.build(:server, :hostname => 'server1.example.com')
    p = Factory.build(:profile, :name => 'linux')
    p.includes << Factory.build(:include, :path => '/')
    p.excludes << Factory.build(:exclude, :path => '/backup')
    p.splits << Factory.build(:split, :path => '/home')
    s.profiles << p
    j = Factory.build(:backup_job, :server => s)
    j.rsyncs.size.should == 62 # a-z,A-Z,0-9
    j.rsyncs.first.should == "/usr/bin/pfexec rsync --stats -aHRW --timeout=3600 --delete-excluded --exclude=.zfs -e 'ssh -c arcfour -p 22' --filter='protect /home' --include=/ --exclude=/backup root@server1.example.com://home/a* /backup/server1.example.com/"
    j.rsyncs.last.should == "/usr/bin/pfexec rsync --stats -aHRW --timeout=3600 --delete-excluded --exclude=.zfs -e 'ssh -c arcfour -p 22' --filter='protect /home' --include=/ --exclude=/backup root@server1.example.com://home/9* /backup/server1.example.com/"
  end

  it "should store more rsyncs if the depth is 2" do
    s = Factory.build(:server, :hostname => 'server1.example.com')
    p = Factory.build(:profile, :name => 'linux')
    p.includes << Factory.build(:include, :path => '/')
    p.excludes << Factory.build(:exclude, :path => '/backup')
    p.splits << Factory.build(:split, :path => '/home', :depth => 2)
    s.profiles << p
    j = Factory.build(:backup_job, :server => s)
    j.rsyncs.size.should == 3844 # a-z,A-Z,0-9
    j.rsyncs.first.should == "/usr/bin/pfexec rsync --stats -aHRW --timeout=3600 --delete-excluded --exclude=.zfs -e 'ssh -c arcfour -p 22' --filter='protect /home' --include=/ --exclude=/backup root@server1.example.com://home/a*/a* /backup/server1.example.com/"
    j.rsyncs.last.should == "/usr/bin/pfexec rsync --stats -aHRW --timeout=3600 --delete-excluded --exclude=.zfs -e 'ssh -c arcfour -p 22' --filter='protect /home' --include=/ --exclude=/backup root@server1.example.com://home/9*/9* /backup/server1.example.com/"
  end

  it "should not add splits if there is a matching include" do
    s = Factory.build(:server, :hostname => 'server1.example.com')
    p = Factory.build(:profile, :name => 'linux')
    p.includes << Factory.build(:include, :path => '/')
    p.excludes << Factory.build(:exclude, :path => '/home')
    p.splits << Factory.build(:split, :path => '/home')
    s.profiles << p
    j = Factory.build(:backup_job, :server => s)
    j.rsyncs.size.should == 0
  end

  it "should have a method to convert exit statusses to a string representation" do
    job = Factory(:backup_job)
    job.code_to_success(0).should == 'OK'
    job.code_to_success(12, 'rsync: Command not found').should == 'FAIL'
    job.code_to_success(127).should == 'FAIL'
    job.code_to_success(12, 'rsync: connection unexpectedly closed (0 bytes received so far)').should == 'FAIL'
    job.code_to_success(25).should == 'PARTIAL'
  end

  it "should have a method for finishing" do
    job = Factory(:backup_job)
    job.finished.should_not be true
    job.finish
    job.finished.should == true
  end

  it "should create commands with a specific label" do
    job = Factory(:backup_job)
    job.run_command('ls', 'listing')
    job.commands.size.should be 1
    job.commands.last.label.should == 'listing'
    job.commands.last.command.should == 'ls 2>&1'
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

  it "should not start the rsyncs if the server is in removal mode" do
    job =  Factory(:backup_job)
    server = job.server
    server.remove_only = true
    server.save
    command = Factory(:command, :exitstatus => 0)
    job.should_receive(:cleanup)
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
    job.stub(:main_rsync).and_return('stub_for_rsync')
    job.should_receive(:run_command).with('stub_for_rsync', "main_rsync")
    job.start_rsyncs
  end

  it "should run split rsyncs after the rsync and update its status" do
    job = Factory(:backup_job)
    command = Factory(:command, :exitstatus => 0)
    now = Time.new
    Time.stub(:new).and_return now
    job.should_receive(:run_split_rsyncs)
    job.after_main_rsync(command)
    job.status.should == 'OK'
  end

  it "should run the first rsync in the array" do
    job = Factory(:backup_job)
    job.stub(:get_rsyncs).and_return('0!RSYNC!1!RSYNC!2')
    job.should_receive(:run_command).with('0', "split_rsync")
    job.run_split_rsyncs
    job.rsyncs.size.should == 2
  end

  it "should delete the first rsync in the array if its not the first call" do
    job = Factory(:backup_job)
    job.stub(:get_rsyncs).and_return('rsync0!RSYNC!rsync1!RSYNC!rsync2')
    job.should_receive(:run_command).with('rsync0', "split_rsync")
    job.run_split_rsyncs
    job.rsyncs.size.should == 2
    job.should_receive(:run_command).with('rsync1', "split_rsync")
    job.run_split_rsyncs
    job.rsyncs.size.should == 1
  end

  it "should create the snapshot after the last rsync command" do
    job = Factory(:backup_job)
    job.stub(:get_rsyncs).and_return('0!RSYNC!1')
    job.run_split_rsyncs
    job.rsyncs.size.should == 1
    job.run_split_rsyncs
    job.rsyncs.size.should == 0
    job.should_receive(:do_snapshot)
    job.run_split_rsyncs
    job.rsyncs.size.should == 0
  end

  it "should not snapshot when the main rsync failed" do
    job = Factory(:backup_job, :status => 'FAIL')
    job.stub(:get_rsyncs).and_return('0!RSYNC!1')
    job.run_split_rsyncs
    job.rsyncs.size.should == 1
    job.run_split_rsyncs
    job.rsyncs.size.should == 0
    job.should_not_receive(:do_snapshot)
    job.run_split_rsyncs
    job.finished.should == true
  end

  it "should cleanup after the snapshot" do
    job = Factory(:backup_job)
    command = Factory(:command, :exitstatus => 0)
    job.should_receive(:cleanup)
    job.after_snapshot(command)
  end

  it "should update the disk usage and ask for the free space for the backup server" do
    job = Factory(:backup_job)
    command = Factory(:command, :exitstatus => 0, :output => '11')
    job.should_receive(:run_command).with("/sbin/zfs list -H backup | awk '{print $3}'", "backupserver_diskspace")
    job.after_diskusage(command)
    job.server.usage.should == 11
  end

  it "should update the snapshots for a server and ask the disk_usage for the server" do
    job = Factory(:backup_job)
    command = Factory(:command, :exitstatus => 0, :output => '1234
5678
90')
    job.should_receive(:run_command).with("/sbin/zfs get -Hp used backup/#{job.server.hostname} | /usr/gnu/bin/awk '{print $3}'", "diskusage")
    job.after_get_snapshots(command)
    job.server.snapshots.should == '1234,5678,90'
  end

  it "should remove old backup jobs for a server" do
    server = Factory.create(:server)
    job = Factory.create(:backup_job, :server => server)
    job.server.should_receive(:cleanup_old_jobs)
    job.should_receive(:remove_old_snapshots)
    job.cleanup
  end

  it "should remove old snapshots for a server" do
    server = Factory.create(:server, :hostname => 'server1', :keep_snapshots => 5, :snapshots => 'snap1,snap2,snap3,snap4,snap5,snap6')
    job = Factory.create(:backup_job, :server => server)
    job.should_receive(:run_command).with("/bin/pfexec /sbin/zfs destroy backup/server1@snap1", "remove_snapshot snap1")
    job.remove_old_snapshots
    server.snapshots.should == 'snap2,snap3,snap4,snap5,snap6'
  end

  it "should get all snapshots for a server when cleanup is done" do
    server = Factory.create(:server, :hostname => 'serverx1', :keep_snapshots => 6, :snapshots => 'snap1,snap2,snap3,snap4,snap5,snap6')
    job = Factory.create(:backup_job, :server => server)
    job.should_receive(:run_command).with("/sbin/zfs list -H -r -o name -t snapshot backup/serverx1 | /usr/gnu/bin/sed -e 's/.*@//'", "get_snapshots")
    job.remove_old_snapshots
    server.snapshots.should == 'snap1,snap2,snap3,snap4,snap5,snap6'
  end

  it "should run split_rsyncs after one rsync is finished" do
    job = Factory(:backup_job)
    job.should_receive(:run_split_rsyncs)
    job.after_split_rsync(true)
  end

  it "should update the diskspace for the backup server" do
    job = Factory(:backup_job)
    command = Factory(:command, :exitstatus => 0, :output => '630G')
    job.after_backupserver_diskspace(command)
    job.backup_server.disk_free.should == '630G'
    job.finished.should == true
  end

  it "should remove the filesystem when there are no snapshots left and server is in removal_only" do
    server = Factory.create(:server, :hostname => 'serverx2', :snapshots => '', :remove_only => true)
    job = Factory.create(:backup_job, :server => server)
    job.should_receive(:run_command).with("/bin/pfexec /sbin/zfs destroy backup/serverx2", "remove_fs")
    job.remove_old_snapshots
  end

  it "should decrease the number of snapshots to keep if all old snapshots are deleted" do
    server = Factory.create(:server, :hostname => 'serverx3', :snapshots => 'snap1,snap2', :keep_snapshots => 2, :remove_only => true)
    job = Factory.create(:backup_job, :server => server)
    job.should_receive(:run_command).with("/sbin/zfs list -H -r -o name -t snapshot backup/serverx3 | /usr/gnu/bin/sed -e 's/.*@//'", "get_snapshots")
    job.remove_old_snapshots
    server.keep_snapshots.should == 1
  end

  it "should only remove a snapshot when there are no snapshots left and server is in removal_only" do
    server = Factory.create(:server, :hostname => 'serverx4', :snapshots => 'snap1,snap2', :keep_snapshots => 1, :remove_only => true)
    job = Factory.create(:backup_job, :server => server)
    job.should_receive(:run_command).with("/bin/pfexec /sbin/zfs destroy backup/serverx4@snap1", "remove_snapshot snap1")
    job.remove_old_snapshots
  end

  it "should remove the server is the filesystem is removed" do
    server = Factory.create(:server, :snapshots => '', :remove_only => true)
    job = Factory.create(:backup_job, :server => server)
    server.should_receive(:destroy)
    job.after_remove_fs(true)
    job.finished?.should == true
  end
end
