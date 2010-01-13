class Server < ActiveRecord::Base
  validates_presence_of :hostname
  
  has_many :profilizations
  has_many :profiles, :through => :profilizations
  
  belongs_to :backup_server
  
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
    return false if backup_running?
    return false unless in_backup_window?
  end
  
  def in_backup_window?
    return true if window_start.blank? or window_stop.blank?
    start_string = window_start == 0 ? "00:00" : "#{window_start}:00"
    stop_string = window_stop == 0 ? "23:59" : "#{window_stop}:00"
    now = Time.new
    start = Time.parse("#{start_string}")
    ending = Time.parse("#{stop_string}:00")
    range = start..ending
    range.include? now
  end
end
