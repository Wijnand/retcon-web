class Server < ActiveRecord::Base
  validates_presence_of :hostname, :interval_hours, :keep_snapshots, :ssh_port
  
  validates_inclusion_of :window_start, :in => 0..23, 
         :message => 'Should be a valid hour! Ranging from 0 to 23', 
         :unless => Proc.new { |server| server.window_start.blank?  }
  validates_inclusion_of :window_stop, :in => 0..23,
         :message => 'Should be a valid hour! Ranging from 0 to 23',
         :unless => Proc.new { |server| server.window_stop.blank?  }
  
  has_many :profilizations
  has_many :profiles, :through => :profilizations
  has_many :problems
  has_many :backup_jobs
  belongs_to :backup_server

  def last_job_status
    return nil unless backup_jobs.size > 0
    backup_jobs.last.status
  end
  
  def latest_problems
    problems.find(:all, :order => 'created_at DESC', :limit=>10)
  end
  
  def latest_jobs
    backup_jobs.find(:all, :order => 'created_at DESC', :limit => self.keep_snapshots)
  end
  
  def to_s
    hostname
  end
  
  def possible_backup_servers
    BackupServer.available_for(connect_to.blank? ? hostname : connect_to)
  end
  
  def backup_running?
    return false if last_started.blank?
    last_started.to_i > last_backup.to_i ? true : false
  end
  
  def should_backup?
    return false unless enabled
    return false unless backup_server
    return false if backup_running?
    return false unless in_backup_window?
    interval_passed?
  end
  
  def in_backup_window?
    return true if window_start.blank? or window_stop.blank?
    start  = Time.parse( window_start == 0 ? "00:00" : "#{window_start}:00")
    ending = Time.parse( window_stop == 0 ? "23:59" : "#{window_stop}:00")
    now = Time.new
    (start..ending).include? now
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
  
  def connect_address
    self.connect_to.blank? ? self.hostname : self.connect_to
  end
  
  def after_initialize
    @enabled = true
    @ssh_port = 22
  end
  
  def startdir
    profiles.first.path
  end
  
  def report(result, job)
  end
end
