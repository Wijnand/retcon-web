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
    BackupJob.code_to_success(0).should == 'OK'
    BackupJob.code_to_success(100).should == 'UNKNOWN'
    BackupJob.code_to_success(1).should == 'FAIL'
    BackupJob.code_to_success(25).should == 'PARTIAL'
  end
end