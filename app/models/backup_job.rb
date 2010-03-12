class BackupJob < ActiveRecord::Base
  belongs_to :server
  belongs_to :backup_server
  
  named_scope :running, :conditions => {:status => 'running'}, :order => 'updated_at DESC'
  named_scope :latest_problems, :conditions => "status NOT IN ('OK','running')", :order => 'updated_at DESC', :limit => 20
  
  def fs
    self.backup_server.zpool + '/' + self.server.hostname
  end
  
  def prepare_fs
    Nanite.request('/zfs/exists', fs, :target => self.backup_server.nanite) do | result |
      res = result[self.backup_server.nanite]
      if res == true
        self.backup_server.after_fs_prepare self
      else
        Nanite.request('/zfs/create', fs, :target => self.backup_server.nanite) do | result |
          res = result[self.backup_server.nanite]
          if res == true
            self.backup_server.after_fs_prepare self
          else
            Problem.create(:backup_server => self.backup_server, 
                           :server => self.server, 
                           :message => "Can not backup: filesystem #{fs} missing on backup server")
             self.status = 'Filesystem preparation failed'
             self.save
          end
        end
      end
    end
  end
  
  def ssh_command
    "ssh -c arcfour -p #{self.server.ssh_port}"
  end
  
  def to_rsync
    "/usr/bin/pfexec rsync --stats -aHRW --del --timeout=600 --delete --delete-excluded --exclude=.zfs -e '#{ssh_command}' " +
    self.server.rsync_excludes + " " + self.server.rsync_includes +
    " --log-file=/tmp/#{self.server}_debug root@#{self.server.connect_address}:#{self.server.startdir} /#{fs}/"
  end
  
  def self.code_to_success(num)
    return "OK" if [0,24].include?(num)
    return "PARTIAL" if [23,30, 20, 25].include?(num)
    return "FAIL" if [12, 1, 2, 3, 5].include?(num)
    return "UNKNOWN"
  end
end
