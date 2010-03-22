class BackupJob < ActiveRecord::Base
  belongs_to :server
  belongs_to :backup_server
  has_many :commands
  named_scope :running, :conditions => {:finished => false}, :order => 'updated_at DESC', :include => [:server, :backup_server]
  named_scope :queued, :conditions => {:status => 'queued'}, :order => 'created_at ASC', :include => [:server, :backup_server]
  named_scope :latest_problems, :conditions => "status NOT IN ('OK','running','queued')", :order => 'updated_at DESC', :limit => 20, :include => [:server, :backup_server]
  
  def fs
    self.backup_server.zpool + '/' + self.server.hostname
  end
  
  def prepare_fs
     run_command("/sbin/zfs list #{self.fs}", "fs_exists")
  end
  
  def run
    self.status = 'running'
    self.finished = false
    save
    prepare_fs
  end
  
  def ssh_command
    "ssh -c arcfour -p #{self.server.ssh_port}"
  end
  
  def to_rsync
    "/usr/bin/pfexec rsync --stats -aHRW --timeout=600 --delete-excluded --exclude=.zfs -e '#{ssh_command}' " +
    self.server.rsync_includes + " " + self.server.rsync_excludes +
    " --log-file=/tmp/#{self.server}_debug root@#{self.server.connect_address}:#{self.server.startdir} /#{fs}/"
  end
  
  def code_to_success(num)
    return "OK" if [0,24].include?(num)
    return "PARTIAL" if [23,30, 20, 25].include?(num)
    return "FAIL" if [12, 1, 2, 3, 5].include?(num)
    return "UNKNOWN"
  end
  
  def run_command(command, label)
    commands.create!(:command => command, :label => label, :user => backup_server.user)
  end
  
  def wakeup
    last = commands.last
    if last.exitstatus
      run_callback(last)
    end
  end
  
  def run_callback(command)
    args = command.label.split(/ /)
    method = args.delete_at(0)
    send('after_' + method, command, *args)
  end
  
  def after_fs_exists(command)
    if command.exitstatus == 0
      start_rsyncs
    else
      run_command("/bin/pfexec /sbin/zfs create #{self.fs}", "create_fs")
    end
  end
  
  def after_create_fs(command)
    if command.exitstatus == 0
      run_command("/sbin/zfs list #{self.fs}", "fs_exists_confirm")
    else
      self.status = 'Unable to create filesystem'
      self.finished = true
      save
    end
  end
  
  def after_fs_exists_confirm(command)
    if command.exitstatus == 0
      start_rsyncs
    else
      self.status = 'Unable to create filesystem'
      self.finished = true
      save
    end
  end
  
  def start_rsyncs
    run_command(self.to_rsync, "rsync")
  end
  
  def after_rsync(command)
    self.status = code_to_success(command.exitstatus)
    save
    run_command("/bin/pfexec /sbin/zfs snapshot #{self.fs}@#{self.updated_at.to_i}", "snapshot")
  end
  
  def after_snapshot(command)
    run_command("/sbin/zfs get -Hp used #{self.fs} | /usr/gnu/bin/awk '{print $3}'", "diskusage")
  end
  
  def after_diskusage(command)
    self.server.usage = command.output.to_i
    self.server.save
    run_command("/sbin/zfs list -H -r -o name -t snapshot #{self.fs} | /usr/gnu/bin/sed -e 's/.*@//'", "get_snapshots")
  end
  
  def after_get_snapshots(command)
    snapshots = command.output.split(/\n/).join(',')
    self.server.snapshots = snapshots
    self.server.save
    self.finished=true
    save
  end
  
end
