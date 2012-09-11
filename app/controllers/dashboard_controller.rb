class DashboardController < ApplicationController

  def index
    @backup_servers = BackupServer.accessible_by(current_ability).find(:all, :order => 'hostname')
    @running = BackupJob.running(:include => [:servers]).select{|j| can? :read, j}
    @failed = BackupJob.latest_problems(:include => [:servers]).select do | job |
      joblist=job.server.backup_jobs.sort!{|j1,j2|j1.id <=> j2.id}
      ( (joblist.last == job && job.status != 'queued') ||
        (job.status == 'queued' && joblist.last(2)[0] == job)
      ) && can?( :read, job)
    end
    @queued = BackupJob.queued(:include => [:servers]).select{|j| can? :read, j}
  end

end
