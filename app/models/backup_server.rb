class BackupServer < ActiveRecord::Base
  has_many :servers
  has_many :backup_jobs
  has_many :problems
  
  validates_presence_of :hostname, :zpool, :max_backups
  attr_accessor :in_subnet
  
  def latest_jobs
    backup_jobs.find(:all, :order => 'created_at DESC', :limit => 50)
  end
  
  def self.available_for(server)
    list = nanite_query("/info/in_subnet?", server)
    recommended = []
    list.each_pair do | server, result |
      recommended.push server if result == true
    end
    available = all
    available.each do | backup_server |
      backup_server.in_subnet = false
      backup_server.in_subnet = true if recommended.include? backup_server.hostname
    end
    available
  end
  
  def to_s
    hostname
  end
  
  def do_nanite(action, payload)
    res = 'undef'
    return [1,'backup server was offline'] unless online?
    Nanite.request(action, payload, :target => nanite) do |result |
     res = result[nanite]
    end
    while res == 'undef'
      sleep 0.1
    end
    return res
  end
  
  def self.nanite_query(action, payload)
    res = 'undef'
    servers = {}
    return servers if nanites.size == 0
    Nanite.request(action, payload, :selector => :all) do | result |
      result.each_pair do | key, value |
        # Strip the nanite- prefix in the hash key
        new_key = key.sub(/nanite-/,'')
        servers[new_key] = value
      end
      res = servers
    end
    while res == 'undef'
      sleep 0.1
    end
    return res
  end
  
  def nanites
    self.class.nanites
  end
  
  def online?
    nanites.include? hostname
  end
  
  def update_disk_space
    if online?
      Nanite.request('/zfs/disk_free', self.zpool, :target => nanite) do |result |
       res = result[nanite]
       self.disk_free = res
       self.save
      end
    end
  end
  
  def self.nanites
    return [] if Nanite.mapper.nil? or Nanite.mapper.cluster.nil?
    Nanite.mapper.cluster.nanites.map do | nanite |
      nanite[0].sub(/nanite-/,'')
    end
  end
  
  def self.array_to_models(arr)
    find(:all, :conditions => [ "hostname IN (?)", arr])
  end
  
  def should_start
    self.servers.select { | server | server.should_backup? }
  end
  
  def queue_backups
    should_start.each do | server |
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
    if job.prepare_fs
      job.status = 'running'
      job.save
      job.server.last_started = Time.new
      job.server.save
      rsync_result = start_rsync job
    else
      job.status = 'failed'
      job.save
    end
  end
  
  def nanite
    "nanite-" + self.hostname
  end
  
  def start_rsync(job)
    Nanite.request('/command/syscmd', job.to_rsync, :target => nanite) do | result |
     res = result[nanite]
     handle_backup_result(res, job)
    end
  end
  
  def handle_backup_result(result, job)
    job.status = BackupJob.code_to_success(result[0])
    job.save
    now = Time.new
    case job.status
    when 'OK', 'PARTIAL', 'UNKNOWN'
      create_snapshot(job)
    when 'FAILED'
      # don't know what to do yet
    end
    job.server.last_backup = job.updated_at
    job.server.save
    # report
  end
  
  def create_snapshot(job)
    time = job.updated_at
    Nanite.push('/command/syscmd', "/usr/bin/pfexec /usr/sbin/zfs snapshot #{job.fs}@#{time.to_i}", :target => nanite)
  end
end
