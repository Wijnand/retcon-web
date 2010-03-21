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
    job.commands.last.label.should be 'listing'
    job.commands.last.command.should be 'ls'
  end
end