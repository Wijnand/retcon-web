class BackupJob < ActiveRecord::Base
  belongs_to :server
  belongs_to :backup_server
  
  named_scope :running, :conditions => {:status => 'running'}, :order => 'updated_at DESC', :include => [:server, :backup_server]
  named_scope :queued, :conditions => {:status => 'queued'}, :order => 'created_at ASC', :include => [:server, :backup_server]
  named_scope :latest_problems, :conditions => "status NOT IN ('OK','running','queued')", :order => 'updated_at DESC', :limit => 20, :include => [:server, :backup_server]
  
  def fs
    self.backup_server.zpool + '/' + self.server.hostname
  end
  
  def prepare_fs

  end
  
  def ssh_command
    "ssh -c arcfour -p #{self.server.ssh_port}"
  end
  
  def to_rsync
    "/usr/bin/pfexec rsync --stats -aHRW --timeout=600 --delete-excluded --exclude=.zfs -e '#{ssh_command}' " +
    self.server.rsync_includes + " " + self.server.rsync_excludes +
    " --log-file=/tmp/#{self.server}_debug root@#{self.server.connect_address}:#{self.server.startdir} /#{fs}/"
  end
  
  def self.code_to_success(num)
    return "OK" if [0,24].include?(num)
    return "PARTIAL" if [23,30, 20, 25].include?(num)
    return "FAIL" if [12, 1, 2, 3, 5].include?(num)
    return "UNKNOWN"
  end
end
