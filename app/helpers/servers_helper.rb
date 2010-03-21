module ServersHelper
  
  def display_backup_duration(job)
    return 'Unknown' unless job
    return 'Not yet started' if job.status == 'queued'
    distance_of_time_in_words(job.created_at, job.updated_at )
  end
end
