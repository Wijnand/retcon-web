module ServersHelper
  
  def display_backup_duration(job)
    return 'Unknown' unless job
    return 'Not yet started' if job.status == 'queued'
    start_time = job.created_at
    end_time = job.updated_at
    
    if job.status == 'running'
      start_time = job.updated_at
      end_time = Time.new
    end
      
    distance_of_time_in_words(start_time, end_time )
  end
end
