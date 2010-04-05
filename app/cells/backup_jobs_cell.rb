class BackupJobsCell < Cell::Base
  def running
    @backup_jobs = BackupJob.running
    render
  end
  
  def problems
    @backup_jobs = BackupJob.latest_problems.select do | job |
      job.server.backup_jobs.last == job
    end
    render
  end
  
  def queued
    @backup_jobs = BackupJob.queued
    render
  end
end
