class BackupJobsCell < Cell::Base
  def running
    @backup_jobs = BackupJob.running
    render
  end
end
