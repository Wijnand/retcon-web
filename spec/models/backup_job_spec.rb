require 'spec_helper'

describe BackupJob do
  it "should create the filesystem if it does not exist" do
    j = Factory(:backup_job)
    j.backup_server.should_receive(:do_nanite).with('/zfs/exists', "#{j.backup_server.zpool}/#{j.server.hostname}").and_return(false)
    j.backup_server.should_receive(:do_nanite).with('/zfs/create', "#{j.backup_server.zpool}/#{j.server.hostname}")
    j.prepare_fs
  end
  
  it "should not create the filesystem if it does exist" do
    j = Factory(:backup_job)
    j.backup_server.should_receive(:do_nanite).with('/zfs/exists', "#{j.backup_server.zpool}/#{j.server.hostname}").and_return(true)
    j.backup_server.should_not_receive(:do_nanite).with('/zfs/create', "#{j.backup_server.zpool}/#{j.server.hostname}")
    j.prepare_fs
  end
  
  it "should build a valid rsync command line" do
    s = Factory.build(:server, :hostname => 'server1.example.com')
    p = Factory.build(:profile, :name => 'linux')
    p.includes << Factory.build(:include, :path => '/')
    p.excludes << Factory.build(:exclude, :path => '/backup')
    s.profiles << p
    j = Factory.build(:backup_job, :server => s)
    j.to_rsync.should == "/usr/bin/pfexec rsync --stats -aHRW --del --timeout=600 --delete --delete-excluded --exclude=.zfs -e 'ssh -c arcfour -p 22' --exclude=/backup --include=/ --log-file=/tmp/server1.example.com_debug root@server1.example.com:/ /backup/server1.example.com/"
  end
  
  it "should have a class method to convert exit statusses to a string representation" do
    BackupJob.code_to_success(0).should == 'OK'
    BackupJob.code_to_success(100).should == 'UNKNOWN'
    BackupJob.code_to_success(1).should == 'FAIL'
    BackupJob.code_to_success(25).should == 'PARTIAL'
  end
end