class BackupJobsCell < Cell::Base
  def running
    @backup_jobs = BackupJob.running
    render
  end
  
  def problems
    @backup_jobs = BackupJob.latest_problems
    render
  end
end
