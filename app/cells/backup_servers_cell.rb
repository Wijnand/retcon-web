class BackupServersCell < Cell::Base
  helper :application
  
  def status
    @backup_servers = BackupServer.find(:all, :include => [:servers, :backup_jobs])
    render
  end
end
