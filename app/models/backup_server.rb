class BackupServer < ActiveRecord::Base
  has_many :servers
  has_many :backup_jobs, :dependent => :destroy
  has_many :problems, :dependent => :destroy
  has_one :user
  
  validates_presence_of :hostname, :zpool, :max_backups
  
  attr_accessor :in_subnet
    
  def self.user_missing
    self.all.select { | b | b.user.nil? }
  end

  def latest_problems
    problems.find(:all, :order => 'created_at DESC', :limit=>10, :include => [:server])
  end
  
  def latest_jobs
    backup_jobs.find(:all, :order => 'updated_at DESC', :limit => 50, :include => [:server])
  end
  
  def to_s
    hostname
  end
  
  def should_start
    self.servers.select { | server | server.should_backup? }
  end
  
  def should_queue
    should_start.select do | server |
      server.backup_jobs.size == 0 or server.backup_jobs.last.status != 'queued'
    end
  end
  
  def queue_backups
    should_queue.each do | server |
      BackupJob.create!(:backup_server => self, :server => server, :status => 'queued')
    end
  end
  
  def queued_backups(opts={})
    backup_jobs.all({:conditions => { :status => 'queued'}, :order => 'created_at ASC' }.merge(opts))
  end
  
  def next_queued
    queued_backups :limit => (self.max_backups - self.running_backups.size)
  end
  
  def running_backups
    backup_jobs.all(:conditions => { :finished => false })
  end
  
  def start_queued
    next_queued.each do | job |
      job.run
    end
  end

end
