class DashboardController < ApplicationController

  def index
    @backup_servers = BackupServer.accessible_by(current_ability).find(:all)
    @running = BackupJob.running(:include => [:servers]).select{|j| can? :read, j}
    @failed = BackupJob.latest_problems(:include => [:servers]).select do | job |
      job.server.backup_jobs.last == job && can?( :read, job)
    end
    @queued = BackupJob.queued(:include => [:servers]).select{|j| can? :read, j}
  end

end
