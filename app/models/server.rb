class Server < ActiveRecord::Base
  validates_presence_of :hostname, :interval_hours
  
  validates_inclusion_of :window_start, :in => 0..23, 
         :message => 'Should be a valid hour! Ranging from 0 to 23', 
         :unless => Proc.new { |server| server.window_start.blank?  }
  validates_inclusion_of :window_stop, :in => 0..23,
         :message => 'Should be a valid hour! Ranging from 0 to 23',
         :unless => Proc.new { |server| server.window_stop.blank?  }
  
  has_many :profilizations
  has_many :profiles, :through => :profilizations
  
  belongs_to :backup_server
  
  after_save :setup_backups
  
  def to_s
    hostname
  end
  
  def possible_backup_servers
    BackupServer.available_for(connect_to.blank? ? hostname : connect_to)
  end
  
  def backup_running?
    return false if last_started.blank?
    last_started > last_backup ? true : false
  end
  
  def should_backup?
    return false unless enabled
    return false if backup_running?
    return false unless in_backup_window?
    interval_passed?
  end
  
  def in_backup_window?
    return true if window_start.blank? or window_stop.blank?
    start_string = window_start == 0 ? "00:00" : "#{window_start}:00"
    stop_string = window_stop == 0 ? "23:59" : "#{window_stop}:00"
    now = Time.new
    start = Time.parse("#{start_string}")
    ending = Time.parse("#{stop_string}")
    range = start..ending
    range.include? now
  end
  
  def interval_passed?
    now = Time.new
    next_backup = last_started + (interval_hours * 3600)
    now > next_backup
  end
  
  def setup_backups
    backup_server.setup_for(self)
  end
  
  def after_initialize
    @enabled = true
  end
end
