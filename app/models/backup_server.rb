class BackupServer < ActiveRecord::Base
  has_many :servers, :include => [:backup_jobs, :problems]
  has_many :backup_jobs, :include => :server
  has_many :problems, :include => :server
  has_one :user
      
  validates_presence_of :hostname, :zpool, :max_backups
  
  attr_accessor :in_subnet
  
  
  def self.user_missing
    self.all.select { | b | b.user.nil? }
  end

  def latest_problems
    problems.find(:all, :order => 'created_at DESC', :limit=>10)
  end
  
  def latest_jobs
    backup_jobs.find(:all, :order => 'updated_at DESC', :limit => 50)
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
  
  def queued_backups
    backup_jobs.all :conditions => { :status => 'queued'}
  end
  
  def next_queued
    backup_jobs.all :conditions => { :status => 'queued'}, :limit => (self.max_backups - self.running_backups.size)
  end
  
  def running_backups
    backup_jobs.all :conditions => { :status => 'running'}
  end
  
  def start_queued
    if online?
      next_queued.each do | job |
        run_backup_job job
      end
    end
  end
  
  def run_backup_job(job)
    job.prepare_fs
  end
  
  def after_fs_prepare(job)
    job.status = 'running'
    job.save
    job.server.last_started = Time.new
    job.server.save
    start_rsync job
  end

  def create_snapshot(job)
  end
  
  def start_rsync(job)

  end
  
  def handle_backup_result(result, job)
    job.status = BackupJob.code_to_success(result[0])
    job.save
    now = Time.new
    case job.status
    when 'OK', 'PARTIAL', 'UNKNOWN'
      create_snapshot(job)
    when 'FAILED'
      create_snapshot(job)
    end
    job.server.save
    job.server.report(result,  job)
  end

end
