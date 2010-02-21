class BackupJob < ActiveRecord::Base
  belongs_to :server
  belongs_to :backup_server
    
  def fs
    self.backup_server.zpool + '/' + self.server.hostname
  end
  
  def prepare_fs
    fs_created = self.backup_server.do_nanite('/zfs/exists', fs)
    unless fs_created
      fs_created = self.backup_server.do_nanite('/zfs/create', fs)
    end
    unless fs_created
      Problem.create(:backup_server => self.backup_server, :server => self.server, :message => "Can not backup: filesystem #{fs} missing on backup server")
      false
    end
  end
  
  def ssh_command
    "ssh -c arcfour -p #{self.server.ssh_port}"
  end
  
  def rsync_command
    "rsync --stats -aHRW --del --timeout=600 --delete --delete-excluded --exclude=.zfs -e '#{ssh_command}' " +
    self.server.excludes + " " + self.server.includes +
    "--log-file=/tmp/#{self.server}_debug root@#{self.server.connect_address}:#{self.server.startdir} /#{fs}/ "
  end
end
