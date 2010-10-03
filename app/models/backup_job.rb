class BackupJob < ActiveRecord::Base
  attr_accessor :start_now
  belongs_to :server
  belongs_to :backup_server
  has_many :commands, :dependent => :destroy
  
  named_scope :running, :conditions => {:finished => false}, :order => 'updated_at DESC', :include => [:server]
  named_scope :queued, :conditions => {:status => 'queued'}, :order => 'created_at ASC', :include => [:server, :backup_server]
  named_scope :latest_problems, :conditions => "status NOT IN ('OK','running','queued', 'done')", :order => 'updated_at DESC', :limit => 20, :include => [:server]
  
  def fs
    self.backup_server.zpool + '/' + self.server.hostname
  end
  
  def prepare_fs
     run_command("/sbin/zfs list #{self.fs}", "fs_exists")
  end
  
  def finish
    self.status = 'done'
    self.finished = true
    save
  end
  
  def run
    self.status = 'running'
    self.started = Time.now
    self.finished = false
    save
    prepare_fs
  end
  
  def display_status
    if self.status == 'queued'
      'queued'
    elsif self.finished == false
      'running'
    else
      self.status
    end
  end
  
  def ssh_command
    "ssh -c arcfour -p #{self.server.ssh_port}"
  end
  
  def main_rsync
    "/usr/bin/pfexec rsync --stats -aHRW --timeout=600 --delete-excluded --exclude=.zfs -e '#{ssh_command}' " +
    server.rsync_protects + " " + server.rsync_includes + " " + 
    server.rsync_split_excludes + " " + server.rsync_excludes +
    " root@#{self.server.connect_address}:#{self.server.startdir} /#{fs}/"
  end
  
  def rsync_template
    "/usr/bin/pfexec rsync --stats -aHRW --timeout=600 --delete-excluded --exclude=.zfs -e '#{ssh_command}' " +
    server.rsync_protects + " " + server.rsync_includes + " " + 
    server.rsync_excludes +
    " root@#{self.server.connect_address}:DIR /#{fs}/"
  end
  
  def rsyncs
    if stored_rsyncs.blank? and !self.last_rsync
      populate_rsyncs
    end
    self.stored_rsyncs.split('!RSYNC!')
  end
  
  def populate_rsyncs
    syncs = get_rsyncs
    self.stored_rsyncs=syncs
    save
  end
  
  def get_rsyncs
    self.server.splits.reject{|s| server.excludes.include? s }.map do | split |
      arr = []
      split_dir = self.server.startdir + split.to_s
      arr.concat(('a'..'z').to_a)
      arr.concat(('A'..'Z').to_a)
      arr.concat((0..9).to_a)
      arr.map do | letter |
        rsync_template.sub('DIR', split_dir + "/#{letter}*")
      end
    end.flatten.join('!RSYNC!')
  end
  
  def code_to_success(num, output='')
    return "OK" if [0,24].include?(num)
    return "FAIL" if [127].include?(num)
    return "FAIL" if Regexp.new(/Command not found/).match(output)
    if match = Regexp.new(/\((\d+) bytes received so far\)/).match(output)
      return "FAIL" if match[1].to_i == 0
    end
    return "PARTIAL"
  end
  
  def run_command(command, label)
    command += ' 2>&1'
    commands.create!(:command => command, :label => label, :user => backup_server.user)
  end
  
  def wakeup
    last = commands.last
    if last && last.exitstatus
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
      if server.remove_only?
        cleanup
      else
        start_rsyncs
      end
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
    run_command(self.main_rsync, "main_rsync")
  end
  
  def after_main_rsync(command)
    self.status = code_to_success(command.exitstatus, command.output)
    save
    run_split_rsyncs
  end
  
  def run_split_rsyncs
    if rsync = get_first_rsync
      run_command(rsync, "split_rsync")
    else
      if self.status == 'FAIL'
        finish
      else
        do_snapshot
      end
    end
  end
  
  def get_first_rsync
    stored = rsyncs
    self.last_rsync = true if stored.size == 1
    command = stored.first
    stored.delete_at 0
    self.stored_rsyncs = stored.join('!RSYNC!')
    save
    command
  end
  
  def do_snapshot
    run_command("/bin/pfexec /sbin/zfs snapshot #{self.fs}@#{self.updated_at.to_i}", "snapshot")
  end
  
  def after_snapshot(command)
    cleanup
  end
  
  def after_split_rsync(command)
    run_split_rsyncs
  end
  
  def cleanup
    server.cleanup_old_jobs
    remove_old_snapshots
  end
  
  def remove_old_snapshots
    snaps = server.current_snapshots
    if server.remove_only?
      self.status = 'OK'
      save
      if snaps.size == server.keep_snapshots
        server.keep_snapshots -= 1
        server.save # next snapshot will vanish on the next run
        run_command("/sbin/zfs list -H -r -o name -t snapshot #{self.fs} | /usr/gnu/bin/sed -e 's/.*@//'", "get_snapshots")
      elsif snaps.size == 0
        run_command("/bin/pfexec /sbin/zfs destroy #{self.fs}", "remove_fs")
      else
        snap = snaps.delete_at(0)
        run_command("/bin/pfexec /sbin/zfs destroy #{self.fs}@#{snap}", "remove_snapshot #{snap}")
        server.snapshots = snaps.join(',')
        server.save
      end
    elsif snaps.size > server.keep_snapshots
      snap = snaps.delete_at(0)
      run_command("/bin/pfexec /sbin/zfs destroy #{self.fs}@#{snap}", "remove_snapshot #{snap}")
      server.snapshots = snaps.join(',')
      server.save
    else
      run_command("/sbin/zfs list -H -r -o name -t snapshot #{self.fs} | /usr/gnu/bin/sed -e 's/.*@//'", "get_snapshots")
    end
  end
  
  def after_remove_snapshot(command, snap)
    remove_old_snapshots
  end
  
  def after_diskusage(command)
    self.server.usage = command.output.to_i
    self.server.save
    run_command("/sbin/zfs list -H #{self.backup_server.zpool} | awk '{print $3}'", "backupserver_diskspace")
  end
  
  def after_get_snapshots(command)
    snapshots = command.output.split(/\n/).join(',') rescue ''
    self.server.snapshots = snapshots
    self.server.save
    run_command("/sbin/zfs get -Hp used #{self.fs} | /usr/gnu/bin/awk '{print $3}'", "diskusage")
  end
  
  def after_backupserver_diskspace(command)
    self.backup_server.disk_free = command.output
    self.backup_server.save
    finish
  end
  
  def after_remove_fs(command)
    server.destroy
    finish
  end
end
