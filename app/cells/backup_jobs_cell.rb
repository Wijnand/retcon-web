class BackupJobsCell < Cell::Base
  def running
    @backup_jobs = BackupJob.accessible_by(current_ability).running(:include => [:servers])
    render
  end
  
  def problems
    @backup_jobs = BackupJob.accessible_by(current_ability).latest_problems(:include => [:servers]).select do | job |
      job.server.backup_jobs.last == job
    end
    render
  end
  
  def queued
    @backup_jobs = BackupJob.accessible_by(current_ability).queued
    render
  end
end
