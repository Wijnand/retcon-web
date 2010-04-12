class Server < ActiveRecord::Base
  validates_presence_of :hostname, :interval_hours, :keep_snapshots, :ssh_port, :backup_server, :path
  
  validates_inclusion_of :window_start, :in => 0..23, 
         :message => 'Should be a valid hour! Ranging from 0 to 23', 
         :unless => Proc.new { |server| server.window_start.blank?  }
  validates_inclusion_of :window_stop, :in => 0..23,
         :message => 'Should be a valid hour! Ranging from 0 to 23',
         :unless => Proc.new { |server| server.window_stop.blank?  }
  
  has_many :profilizations
  has_many :profiles, :through => :profilizations
  has_many :problems, :include => :backup_server
  has_many :backup_jobs, :include => :backup_server
  belongs_to :backup_server

  def previous_jobs
    backup_jobs.find(:all, :order => 'created_at ASC')
  end
  
  def last_job_status
    return nil unless backup_jobs.size > 0
    backup_jobs.last.status
  end
  
  def latest_problems
    problems.find(:all, :order => 'created_at DESC', :limit=>10, :include => :backup_server)
  end
  
  def latest_jobs
    backup_jobs.find(:all, :order => 'created_at DESC', :limit => self.keep_snapshots, :include => :backup_server)
  end
  
  def to_s
    hostname
  end
  
  def possible_backup_servers
    BackupServer.available_for(connect_to.blank? ? hostname : connect_to)
  end
  
  def backup_running?
    return false if self.backup_jobs.size == 0
    return true if self.backup_jobs.queued.size > 0
    return true if self.backup_jobs.running.size > 0
    false
  end
  
  def should_backup?
    return false unless enabled
    return false unless backup_server
    return false if backup_running?
    return false unless in_backup_window?
    interval_passed?
  end
  
  def in_backup_window?
    start = window_start || 0
    stop = window_stop || 0
    now = Time.new
    stop < start ? endday=now.tomorrow : endday = now
    endday = endday.strftime('%Y-%m-%d')
    start  = Time.parse( start == 0 ? "00:00" : "#{start}:00").to_i
    ending = Time.parse( stop == 0 ? "#{endday} 23:59" : "#{endday} #{stop}:00").to_i
    (start..ending).include? now.to_i
  end
  
  def excludes
    self.profiles.map{ | p | p.excludes }.flatten
  end
  
  def rsync_excludes
    excludes.map { | e | "--exclude=#{e}"}.join(" ")
  end
  
  def includes
    self.profiles.map{ | p | p.includes }.flatten
  end
  
  def rsync_includes
    includes.map { | i | "--include=#{i}"}.join(" ")
  end
  
  def interval_passed?
    return true if last_started.nil?
    now = Time.new
    next_backup = last_started + (interval_hours * 3600)
    now > next_backup
  end
  
  def last_backup
    return nil if self.backup_jobs.size == 0
    self.previous_jobs.last.updated_at
  end
  
  def last_started
    return nil if self.backup_jobs.size == 0
    self.previous_jobs.last.created_at
  end
  
  def connect_address
    self.connect_to.blank? ? self.hostname : self.connect_to
  end
  
  def startdir
    self.path || '/'
  end
  
  def report(result, job)
  end
  
  def current_snapshots
    (self.snapshots || '').split(',')
  end
  
  def queue_backup
    backup_jobs.create(:backup_server => self.backup_server, :status => 'queued')
  end
end
