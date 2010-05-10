class BackupJobsCell < Cell::Base
  def running
    @backup_jobs = BackupJob.running(:include => [:servers])
    render
  end
  
  def problems
    @backup_jobs = BackupJob.latest_problems(:include => [:servers]).select do | job |
      job.server.backup_jobs.last == job
    end
    render
  end
  
  def queued
    @backup_jobs = BackupJob.queued(:include => [:servers])
    render
  end
end
