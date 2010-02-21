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
    j = Factory(:backup_job)
    j.server.should_receive(:startdir).and_return('/')
    puts j.rsync_command
    pending
  end
end